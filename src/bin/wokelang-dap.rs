// SPDX-License-Identifier: MPL-2.0
//! WokeLang Debug Adapter Protocol (DAP) server

use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use wokelang::dap::{DapRequest, DapResponse, DapServer};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let listener = TcpListener::bind("127.0.0.1:4712")?;
    println!("WokeLang DAP server listening on 127.0.0.1:4712");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                std::thread::spawn(|| {
                    if let Err(e) = handle_client(stream) {
                        eprintln!("Error handling client: {}", e);
                    }
                });
            }
            Err(e) => {
                eprintln!("Error accepting connection: {}", e);
            }
        }
    }

    Ok(())
}

fn handle_client(stream: TcpStream) -> Result<(), Box<dyn std::error::Error>> {
    let reader = BufReader::new(stream.try_clone()?);
    let mut writer = stream.try_clone()?;

    let mut dap_server = DapServer::new();

    for line in reader.lines() {
        let line = line?;
        let request: DapRequest = serde_json::from_str(&line)?;
        let response = dap_server.handle_request(request);
        let response_json = serde_json::to_string(&response)?;
        writeln!(writer, "{}", response_json)?;
    }

    Ok(())
}
