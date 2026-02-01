// SPDX-License-Identifier: PMPL-1.0-or-later
// VSCode extension for WokeLang language support

import * as path from 'path';
import { workspace, ExtensionContext } from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: ExtensionContext) {
  // Get woke-lsp executable path from settings
  const config = workspace.getConfiguration('wokelang');
  const serverPath = config.get<string>('serverPath', 'woke-lsp');

  // Server options - launch woke-lsp command
  const serverOptions: ServerOptions = {
    command: serverPath,
    args: [],
    options: {
      env: process.env
    }
  };

  // Client options
  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'wokelang' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.woke')
    }
  };

  // Create and start the language client
  client = new LanguageClient(
    'wokelang',
    'WokeLang Language Server',
    serverOptions,
    clientOptions
  );

  // Start the client (this will also launch the server)
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}
