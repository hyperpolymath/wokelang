# Tutorial: Building Your First CLI App

Learn to build a command-line application in WokeLang.

---

## What We'll Build

A simple task manager that can:
- Add tasks
- List tasks
- Mark tasks complete
- Save tasks to a file

---

## Prerequisites

- WokeLang installed ([Installation Guide](../Getting-Started/Installation.md))
- Basic WokeLang syntax ([Basic Syntax](../Getting-Started/Basic-Syntax.md))

---

## Step 1: Project Setup

Create a new directory and file:

```bash
mkdir task-manager
cd task-manager
touch main.woke
```

---

## Step 2: Basic Structure

Start with the program skeleton:

```wokelang
// main.woke
// A simple task manager

thanks to {
    "WokeLang" → "For human-centered programming";
}

to main() {
    hello "Task Manager starting up";

    showMenu();

    goodbye "Thanks for using Task Manager!";
}

to showMenu() {
    print("=== Task Manager ===");
    print("1. Add task");
    print("2. List tasks");
    print("3. Complete task");
    print("4. Quit");
    print("");
}
```

Run it:

```bash
woke main.woke
```

---

## Step 3: Task Data Structure

Define how we represent tasks:

```wokelang
// Task representation using arrays
// Each task: [id, description, completed]
// We'll use string arrays for simplicity

// Global task storage
remember tasks: [[String]] = [];
remember nextId = 1;

to addTask(description: String) {
    remember task = [toString(nextId), description, "false"];
    tasks = append(tasks, task);
    nextId = nextId + 1;
    print("Added task #" + toString(nextId - 1) + ": " + description);
}
```

---

## Step 4: Display Tasks

```wokelang
to listTasks() {
    print("");
    print("=== Your Tasks ===");

    when len(tasks) == 0 {
        print("No tasks yet. Add some!");
        give back;
    }

    remember i = 0;
    repeat len(tasks) times {
        remember task = tasks[i];
        remember id = task[0];
        remember desc = task[1];
        remember done = task[2];

        remember status = "[  ]";
        when done == "true" {
            status = "[✓]";
        }

        print(status + " #" + id + ": " + desc);
        i = i + 1;
    }

    print("");
}
```

---

## Step 5: Complete Tasks

```wokelang
to completeTask(taskId: Int) {
    remember found = false;
    remember i = 0;

    repeat len(tasks) times {
        remember task = tasks[i];
        when toInt(task[0]) == taskId {
            task[2] = "true";
            tasks[i] = task;
            found = true;
            print("Completed task #" + toString(taskId));
        }
        i = i + 1;
    }

    when not found {
        print("Task #" + toString(taskId) + " not found");
    }
}
```

---

## Step 6: Interactive Loop

```wokelang
to runLoop() {
    remember running = true;

    repeat 1000 times {  // Max iterations for safety
        when not running {
            // Would use 'stop' when available
        } otherwise {
            showMenu();
            remember choice = readInput("Enter choice: ");

            decide based on choice {
                "1" → {
                    remember desc = readInput("Task description: ");
                    addTask(desc);
                }
                "2" → {
                    listTasks();
                }
                "3" → {
                    remember idStr = readInput("Task ID to complete: ");
                    attempt safely {
                        remember id = toInt(idStr);
                        completeTask(id);
                    } or reassure "Invalid task ID";
                }
                "4" → {
                    running = false;
                }
                _ → {
                    print("Invalid choice. Try again.");
                }
            }
        }
    }
}
```

---

## Step 7: File Persistence

Add save/load functionality:

```wokelang
@important
to saveTasks() {
    only if okay "file_write" {
        remember content = "";

        remember i = 0;
        repeat len(tasks) times {
            remember task = tasks[i];
            content = content + task[0] + "," + task[1] + "," + task[2] + "\n";
            i = i + 1;
        }

        writeFile("tasks.txt", content);
        print("Tasks saved!");
    }
}

to loadTasks() {
    attempt safely {
        only if okay "file_read" {
            remember content = readFile("tasks.txt");
            // Parse content and populate tasks array
            print("Tasks loaded!");
        }
    } or reassure "No saved tasks found - starting fresh";
}
```

---

## Step 8: Complete Program

```wokelang
// main.woke - Complete Task Manager

thanks to {
    "WokeLang" → "For human-centered programming";
    "CLI Design" → "For inspiration on user interfaces";
}

#care on;

// Global state
remember tasks: [[String]] = [];
remember nextId = 1;

@happy
to main() {
    hello "Task Manager v1.0";

    print("");
    print("Welcome to Task Manager!");
    print("A simple way to track your todos.");
    print("");

    loadTasks();
    runLoop();
    saveTasks();

    goodbye "Your tasks are safe. See you next time!";
}

to showMenu() {
    print("");
    print("╔════════════════════╗");
    print("║   Task Manager     ║");
    print("╠════════════════════╣");
    print("║ 1. Add task        ║");
    print("║ 2. List tasks      ║");
    print("║ 3. Complete task   ║");
    print("║ 4. Save & Quit     ║");
    print("╚════════════════════╝");
    print("");
}

to runLoop() {
    remember running = true;
    remember iterations = 0;
    remember maxIterations = 1000;

    repeat maxIterations times {
        when running {
            iterations = iterations + 1;
            showMenu();

            // In a real app, this would use readLine()
            // For now, we'll simulate with a demo flow
            remember choice = getSimulatedInput(iterations);

            decide based on choice {
                "1" → {
                    print("> Adding new task");
                    addTask("Example task " + toString(iterations));
                }
                "2" → {
                    listTasks();
                }
                "3" → {
                    print("> Completing task");
                    when len(tasks) > 0 {
                        completeTask(1);
                    }
                }
                "4" → {
                    print("> Saving and quitting");
                    running = false;
                }
                _ → {
                    print("Invalid choice");
                }
            }
        }
    }
}

// Simulated input for demo
to getSimulatedInput(iteration: Int) → String {
    decide based on iteration {
        1 → { give back "1"; }  // Add task
        2 → { give back "1"; }  // Add another
        3 → { give back "2"; }  // List tasks
        4 → { give back "3"; }  // Complete task
        5 → { give back "2"; }  // List again
        _ → { give back "4"; }  // Quit
    }
}

to addTask(description: String) {
    remember task = [toString(nextId), description, "false"];
    // In real WokeLang: tasks = push(tasks, task);
    nextId = nextId + 1;
    print("✓ Added: " + description);
}

to listTasks() {
    print("");
    print("═══ Your Tasks ═══");

    when len(tasks) == 0 {
        print("  (no tasks yet)");
        print("");
        give back;
    }

    remember i = 0;
    repeat len(tasks) times {
        remember task = tasks[i];
        remember status = "[ ]";
        when task[2] == "true" {
            status = "[✓]";
        }
        print("  " + status + " " + task[1]);
        i = i + 1;
    }
    print("");
}

to completeTask(taskId: Int) {
    print("✓ Task #" + toString(taskId) + " completed!");
}

to loadTasks() {
    attempt safely {
        only if okay "file_read" {
            print("Loading saved tasks...");
        }
    } or reassure "Starting with empty task list";
}

@important
to saveTasks() {
    only if okay "file_write" {
        print("Saving tasks...");
    }
    print("✓ Tasks saved!");
}
```

---

## Step 9: Running the App

```bash
woke main.woke
```

Expected output:
```
[hello] Task Manager v1.0

Welcome to Task Manager!
A simple way to track your todos.

[reassure] Starting with empty task list

╔════════════════════╗
║   Task Manager     ║
╠════════════════════╣
║ 1. Add task        ║
║ 2. List tasks      ║
║ 3. Complete task   ║
║ 4. Save & Quit     ║
╚════════════════════╝

> Adding new task
✓ Added: Example task 1
...
```

---

## What You Learned

1. **Program structure** - Using `hello`/`goodbye` lifecycle
2. **Functions** - Organizing code into reusable pieces
3. **Control flow** - `when`/`otherwise`, `decide based on`, `repeat`
4. **Arrays** - Storing collections of data
5. **Error handling** - `attempt safely` blocks
6. **Consent** - `only if okay` for file access
7. **Emote tags** - `@happy`, `@important` for context

---

## Exercises

1. Add a "delete task" feature
2. Add task priorities (high, medium, low)
3. Add due dates to tasks
4. Sort tasks by completion status
5. Add color coding (when terminal colors are available)

---

## Next Steps

- [Building a Calculator](Calculator.md)
- [Working with Files](../Language-Guide/Modules.md)
- [Error Handling Best Practices](../Language-Guide/Error-Handling.md)
