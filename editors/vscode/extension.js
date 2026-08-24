const vscode = require('vscode');
const { LanguageClient, TransportKind } = require('vscode-languageclient/node');

let client;

function activate(context) {
    const config = vscode.workspace.getConfiguration('wokelang');
    const serverPath = config.get('serverPath', 'woke-lsp');
    
    // Server options
    const serverOptions = {
        run: { command: serverPath, transport: TransportKind.stdio },
        debug: { command: serverPath, transport: TransportKind.stdio }
    };

    // Client options
    const clientOptions = {
        documentSelector: [{ scheme: 'file', language: 'wokelang' }],
        synchronize: {
            configurationSection: 'wokelang'
        },
        initializationOptions: {
            enableDiagnostics: config.get('enableDiagnostics', true),
            enableCompletion: config.get('enableCompletion', true),
            enableHover: config.get('enableHover', true),
            enableFormatting: config.get('enableFormatting', true)
        }
    };

    // Create the language client
    client = new LanguageClient(
        'wokelangLsp',
        'WokeLang Language Server',
        serverOptions,
        clientOptions
    );

    // Register commands
    context.subscriptions.push(
        vscode.commands.registerCommand('wokelang.restartServer', async () => {
            if (client) {
                await client.stop();
                client.start();
                vscode.window.showInformationMessage('WokeLang LSP restarted.');
            }
        }),
        vscode.commands.registerCommand('wokelang.showInfo', () => {
            if (client) {
                vscode.window.showInformationMessage(\WokeLang LSP running at: \);
            }
        }),
        vscode.commands.registerCommand('wokelang.checkConsent', async () => {
            if (client) {
                const editor = vscode.window.activeTextEditor;
                if (editor) {
                    await vscode.commands.executeCommand('wokelang.internal.checkConsent', editor.document.uri.toString());
                    vscode.window.showInformationMessage('Consent check triggered.');
                }
            }
        }),
        vscode.commands.registerCommand('wokelang.formatDocument', async () => {
            const editor = vscode.window.activeTextEditor;
            if (editor) {
                await vscode.commands.executeCommand('editor.action.formatDocument');
            }
        })
    );

    // Start the client
    client.start();
}

function deactivate() {
    if (!client) {
        return undefined;
    }
    return client.stop();
}

module.exports = {
    activate,
    deactivate
};
