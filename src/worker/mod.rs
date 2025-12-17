//! Async Worker System for WokeLang
//!
//! This module provides true async workers with message passing capabilities.

use crate::interpreter::Value;
use std::collections::HashMap;
use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread::{self, JoinHandle};

/// Message that can be sent between workers
#[derive(Debug, Clone)]
pub enum WorkerMessage {
    /// A value being sent to a worker
    Value(Value),
    /// Request to stop the worker
    Stop,
    /// Ping for health check
    Ping,
    /// Pong response to ping
    Pong,
    /// Custom named message with value
    Named(String, Value),
}

/// Handle to a spawned worker
pub struct WorkerHandle {
    /// Thread handle
    handle: Option<JoinHandle<()>>,
    /// Channel to send messages to the worker
    sender: Sender<WorkerMessage>,
    /// Channel to receive messages from the worker
    receiver: Receiver<WorkerMessage>,
    /// Worker name
    pub name: String,
    /// Whether the worker is still running
    running: Arc<Mutex<bool>>,
}

impl WorkerHandle {
    /// Send a message to the worker
    pub fn send(&self, msg: WorkerMessage) -> Result<(), String> {
        self.sender
            .send(msg)
            .map_err(|e| format!("Failed to send message: {}", e))
    }

    /// Try to receive a message from the worker (non-blocking)
    pub fn try_receive(&self) -> Option<WorkerMessage> {
        self.receiver.try_recv().ok()
    }

    /// Receive a message from the worker (blocking)
    pub fn receive(&self) -> Result<WorkerMessage, String> {
        self.receiver
            .recv()
            .map_err(|e| format!("Failed to receive message: {}", e))
    }

    /// Check if the worker is still running
    pub fn is_running(&self) -> bool {
        *self.running.lock().unwrap()
    }

    /// Stop the worker and wait for it to finish
    pub fn stop(mut self) -> Result<(), String> {
        // Send stop signal
        let _ = self.sender.send(WorkerMessage::Stop);

        // Wait for thread to finish
        if let Some(handle) = self.handle.take() {
            handle
                .join()
                .map_err(|_| "Worker thread panicked".to_string())?;
        }

        Ok(())
    }

    /// Wait for the worker to finish without stopping it
    pub fn join(mut self) -> Result<(), String> {
        if let Some(handle) = self.handle.take() {
            handle
                .join()
                .map_err(|_| "Worker thread panicked".to_string())?;
        }
        Ok(())
    }
}

/// Worker context provided to the worker function
pub struct WorkerContext {
    /// Channel to send messages back to the parent
    sender: Sender<WorkerMessage>,
    /// Channel to receive messages from the parent
    receiver: Receiver<WorkerMessage>,
    /// Running flag
    running: Arc<Mutex<bool>>,
}

impl WorkerContext {
    /// Send a message to the parent
    pub fn send(&self, msg: WorkerMessage) -> Result<(), String> {
        self.sender
            .send(msg)
            .map_err(|e| format!("Failed to send message: {}", e))
    }

    /// Try to receive a message (non-blocking)
    pub fn try_receive(&self) -> Option<WorkerMessage> {
        self.receiver.try_recv().ok()
    }

    /// Receive a message (blocking)
    pub fn receive(&self) -> Result<WorkerMessage, String> {
        self.receiver
            .recv()
            .map_err(|e| format!("Failed to receive message: {}", e))
    }

    /// Check if the worker should continue running
    pub fn should_run(&self) -> bool {
        *self.running.lock().unwrap()
    }

    /// Mark the worker as stopped
    pub fn mark_stopped(&self) {
        *self.running.lock().unwrap() = false;
    }
}

/// Worker pool for managing multiple workers
pub struct WorkerPool {
    workers: HashMap<String, WorkerHandle>,
    max_workers: usize,
}

impl WorkerPool {
    /// Create a new worker pool with a maximum number of workers
    pub fn new(max_workers: usize) -> Self {
        Self {
            workers: HashMap::new(),
            max_workers,
        }
    }

    /// Spawn a new worker with a custom function
    pub fn spawn<F>(&mut self, name: String, f: F) -> Result<(), String>
    where
        F: FnOnce(WorkerContext) + Send + 'static,
    {
        if self.workers.len() >= self.max_workers {
            return Err(format!(
                "Worker pool full (max {} workers)",
                self.max_workers
            ));
        }

        if self.workers.contains_key(&name) {
            return Err(format!("Worker '{}' already exists", name));
        }

        let handle = spawn_worker(name.clone(), f);
        self.workers.insert(name, handle);
        Ok(())
    }

    /// Get a reference to a worker handle
    pub fn get(&self, name: &str) -> Option<&WorkerHandle> {
        self.workers.get(name)
    }

    /// Send a message to a specific worker
    pub fn send_to(&self, name: &str, msg: WorkerMessage) -> Result<(), String> {
        self.workers
            .get(name)
            .ok_or_else(|| format!("Worker '{}' not found", name))?
            .send(msg)
    }

    /// Broadcast a message to all workers
    pub fn broadcast(&self, msg: WorkerMessage) -> Vec<String> {
        let mut errors = Vec::new();
        for (name, worker) in &self.workers {
            if let Err(e) = worker.send(msg.clone()) {
                errors.push(format!("{}: {}", name, e));
            }
        }
        errors
    }

    /// Stop a specific worker
    pub fn stop(&mut self, name: &str) -> Result<(), String> {
        let worker = self
            .workers
            .remove(name)
            .ok_or_else(|| format!("Worker '{}' not found", name))?;
        worker.stop()
    }

    /// Stop all workers
    pub fn stop_all(&mut self) -> Vec<String> {
        let mut errors = Vec::new();
        let names: Vec<String> = self.workers.keys().cloned().collect();
        for name in names {
            if let Err(e) = self.stop(&name) {
                errors.push(format!("{}: {}", name, e));
            }
        }
        errors
    }

    /// Get the number of active workers
    pub fn active_count(&self) -> usize {
        self.workers.values().filter(|w| w.is_running()).count()
    }

    /// Get all worker names
    pub fn worker_names(&self) -> Vec<String> {
        self.workers.keys().cloned().collect()
    }
}

impl Default for WorkerPool {
    fn default() -> Self {
        Self::new(16)
    }
}

/// Spawn a worker with a custom function
pub fn spawn_worker<F>(name: String, f: F) -> WorkerHandle
where
    F: FnOnce(WorkerContext) + Send + 'static,
{
    // Create channels for bidirectional communication
    let (parent_tx, worker_rx) = mpsc::channel();
    let (worker_tx, parent_rx) = mpsc::channel();

    let running = Arc::new(Mutex::new(true));
    let running_clone = running.clone();

    let handle = thread::spawn(move || {
        let ctx = WorkerContext {
            sender: worker_tx,
            receiver: worker_rx,
            running: running_clone,
        };

        f(ctx);
    });

    WorkerHandle {
        handle: Some(handle),
        sender: parent_tx,
        receiver: parent_rx,
        name,
        running,
    }
}

/// Cancellation token for worker tasks
#[derive(Clone)]
pub struct CancellationToken {
    cancelled: Arc<Mutex<bool>>,
}

impl CancellationToken {
    pub fn new() -> Self {
        Self {
            cancelled: Arc::new(Mutex::new(false)),
        }
    }

    /// Cancel the token
    pub fn cancel(&self) {
        *self.cancelled.lock().unwrap() = true;
    }

    /// Check if cancelled
    pub fn is_cancelled(&self) -> bool {
        *self.cancelled.lock().unwrap()
    }
}

impl Default for CancellationToken {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_worker_spawn() {
        let handle = spawn_worker("test".to_string(), |ctx| {
            // Worker just sends a pong and exits
            ctx.send(WorkerMessage::Pong).unwrap();
            ctx.mark_stopped();
        });

        // Wait for message
        let msg = handle.receive().unwrap();
        assert!(matches!(msg, WorkerMessage::Pong));

        handle.join().unwrap();
    }

    #[test]
    fn test_worker_message_passing() {
        let handle = spawn_worker("echo".to_string(), |ctx| {
            loop {
                match ctx.receive() {
                    Ok(WorkerMessage::Value(v)) => {
                        // Echo back
                        ctx.send(WorkerMessage::Value(v)).unwrap();
                    }
                    Ok(WorkerMessage::Stop) => {
                        ctx.mark_stopped();
                        break;
                    }
                    _ => {}
                }
            }
        });

        // Send a value
        handle.send(WorkerMessage::Value(Value::Int(42))).unwrap();

        // Receive echo
        let msg = handle.receive().unwrap();
        if let WorkerMessage::Value(Value::Int(n)) = msg {
            assert_eq!(n, 42);
        } else {
            panic!("Expected Value(Int(42))");
        }

        handle.stop().unwrap();
    }

    #[test]
    fn test_worker_pool() {
        let mut pool = WorkerPool::new(4);

        // Spawn workers
        pool.spawn("worker1".to_string(), |ctx| {
            ctx.send(WorkerMessage::Value(Value::Int(1))).unwrap();
            while ctx.should_run() {
                if let Some(WorkerMessage::Stop) = ctx.try_receive() {
                    ctx.mark_stopped();
                }
                std::thread::sleep(std::time::Duration::from_millis(10));
            }
        })
        .unwrap();

        pool.spawn("worker2".to_string(), |ctx| {
            ctx.send(WorkerMessage::Value(Value::Int(2))).unwrap();
            while ctx.should_run() {
                if let Some(WorkerMessage::Stop) = ctx.try_receive() {
                    ctx.mark_stopped();
                }
                std::thread::sleep(std::time::Duration::from_millis(10));
            }
        })
        .unwrap();

        assert_eq!(pool.active_count(), 2);

        // Stop all workers
        let errors = pool.stop_all();
        assert!(errors.is_empty());
    }

    #[test]
    fn test_cancellation_token() {
        let token = CancellationToken::new();
        assert!(!token.is_cancelled());

        let token_clone = token.clone();
        token.cancel();

        assert!(token.is_cancelled());
        assert!(token_clone.is_cancelled());
    }
}
