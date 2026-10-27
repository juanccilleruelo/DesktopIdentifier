# Winget package

Manifest for submitting **Desktop Identifier** to the
[Windows Package Manager community repository](https://github.com/microsoft/winget-pkgs).

> **Before submitting the Desktop-tab build:** the URL and hash below belong to
> the earlier 1.1.0.0 installer (commit `278d898`). After rebuilding
> `dist\DesktopIdentifier-Setup.exe`, update `InstallerUrl` to the new committed
> setup and replace `InstallerSha256` with its hash, or publish a new version.
> The local setup built with the Desktop tab has SHA-256
> `9D11AD53F7502C945722751B3EC591E165EE55497FD8064177E50D10DAD2895D`; it is not
> public until it is committed.

| | |
|---|---|
| Package identifier | `JuanCCilleruelo.DesktopIdentifier` |
| Version | `1.1.0.0` |
| Installer | Inno Setup, per-user, x86 |
| Installer URL | GitHub raw, commit `278d898` |
| SHA-256 | `FD3AF507C7B15C693779255DF5D3BBF0DCA4B66F3C134557E9D0814696EAE8CE` |

The manifest is a **singleton** manifest:

```
winget/manifests/j/JuanCCilleruelo/DesktopIdentifier/1.1.0.0/
    JuanCCilleruelo.DesktopIdentifier.yaml
```

## Validate locally

```powershell
winget validate --manifest .\manifests\j\JuanCCilleruelo\DesktopIdentifier\1.1.0.0\JuanCCilleruelo.DesktopIdentifier.yaml
```

## Test locally

Local manifest installs are disabled by default on Windows. An administrator
must enable them first:

```powershell
winget settings --enable LocalManifestFiles
```

Then:

```powershell
winget install --manifest .\manifests\j\JuanCCilleruelo\DesktopIdentifier\1.1.0.0\JuanCCilleruelo.DesktopIdentifier.yaml --accept-package-agreements --accept-source-agreements
```

The installer is silent (`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`) and installs
per user. The current installer URL is immutable because it points to a commit;
for future releases, prefer a versioned GitHub Release asset and update
`InstallerUrl` and `InstallerSha256`.

## Submit to winget-pkgs

1. Fork [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs).
2. Copy the `manifests` directory contents into the fork, keeping the same path:
   `manifests/j/JuanCCilleruelo/DesktopIdentifier/1.1.0.0/`.
3. Commit and push the fork.
4. Open a pull request against `microsoft/winget-pkgs`.
5. Wait for the automated validation and moderation.

After the pull request is merged:

```powershell
winget search DesktopIdentifier
winget install JuanCCilleruelo.DesktopIdentifier
winget upgrade JuanCCilleruelo.DesktopIdentifier
```
