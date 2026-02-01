// SPDX-License-Identifier: PMPL-1.0-or-later
// WokeLang VSCode Extension - ReScript Implementation

open VSCode

let client: ref<option<LanguageClient.t>> = ref(None)

let startLanguageClient = (_context: extensionContext) => {
  let config = Workspace.getConfiguration("wokelang")
  let serverPath = switch Workspace.get(config, "serverPath") {
  | Some(path) => path
  | None => "woke-lsp"
  }

  let serverOptions: LanguageClient.serverOptions = {
    run: {
      command: serverPath,
      transport: Stdio,
    },
    debug: {
      command: serverPath,
      transport: Stdio,
      options: {env: Js.Dict.fromArray([("RUST_BACKTRACE", "1")])},
    },
  }

  let clientOptions: LanguageClient.clientOptions = {
    documentSelector: [{scheme: "file", language: "wokelang"}],
    synchronize: {
      fileEvents: Workspace.createFileSystemWatcher("**/*.woke"),
    },
  }

  let languageClient = LanguageClient.make(
    "wokelang",
    "WokeLang Language Server",
    serverOptions,
    clientOptions,
  )

  client := Some(languageClient)
  let _ = LanguageClient.start(languageClient)
  ()
}

let restartServer = (context: extensionContext) => {
  switch client.contents {
  | Some(c) =>
    let _ = LanguageClient.stop(c)
    startLanguageClient(context)
  | None => startLanguageClient(context)
  }
}

let activate = (context: extensionContext) => {
  startLanguageClient(context)

  // Register commands
  let restartCmd = Commands.registerCommand("wokelang.restartServer", () =>
    Js.Promise.make((~resolve, ~reject as _) => {
      restartServer(context)
      resolve(.)
    })
  )

  let _ = Js.Array2.push(context.subscriptions, restartCmd)
  ()
}

let deactivate = () => {
  switch client.contents {
  | Some(c) => Some(LanguageClient.stop(c))
  | None => None
  }
}
