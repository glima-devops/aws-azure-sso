[![view on npm](http://img.shields.io/npm/v/aws-azure-sso.svg)](https://www.npmjs.org/package/aws-azure-sso)
[![npm module downloads per month](http://img.shields.io/npm/dm/aws-azure-sso.svg)](https://www.npmjs.org/package/aws-azure-sso)

# aws-azure-sso

If your organization uses [Azure Active Directory](https://azure.microsoft.com) to provide SSO login to the AWS console, then there is no easy way to log in on the command line or to use the [AWS CLI](https://aws.amazon.com/cli/). This tool fixes that. It lets you use the normal Azure AD login (including MFA) from a command line to create a federated AWS session and places the temporary credentials in the proper place for the AWS CLI and SDKs.

## Installation

Installation can be done in any of the following platform - Windows, Linux, Docker, Snap

### Windows

Install [Node.js](https://nodejs.org/) v22 or higher (v20.19 is the minimum — the ESM-only dependencies need a Node that can `require()` an ES module). Then install aws-azure-sso with npm:

    npm install -g aws-azure-sso

This fork uses `puppeteer-core` and does **not** download a bundled Chromium. You must have Microsoft Edge, Google Chrome, or Chromium already installed. The tool auto-detects the browser from known paths — **Edge first** (since this tool is for Azure AD SSO), Chrome as fallback. If it cannot find one, set the `PUPPETEER_EXECUTABLE_PATH` environment variable to your browser executable.

### Linux

In Linux you can either install for all users or just the current user. In either case, you must first install [Node.js](https://nodejs.org/) v22 or higher (v20.19 minimum) and any [puppeteer dependencies](https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md#chrome-headless-doesnt-launch). Then follow the appropriate instructions.

#### Option A: Install for All Users

Install aws-azure-sso globally with npm:

    sudo npm install -g aws-azure-sso --unsafe-perm

> Older versions needed `sudo chmod -R go+rx $(npm root -g)` here, to make the bundled Chromium executable for all users. This fork ships no browser, so that step is no longer required.

#### Option B: Install Only for Current User

First configure npm to install global packages in [your home directory](https://docs.npmjs.com/getting-started/fixing-npm-permissions):

    mkdir ~/.npm-global
    npm config set prefix '~/.npm-global'
    export PATH=~/.npm-global/bin:$PATH
    source ~/.profile
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.profile
    source ~/.profile

Then install aws-azure-sso:

    npm install -g aws-azure-sso

### Docker

A Docker image has been built with aws-azure-sso preinstalled. You simply need to run the command with a volume mounted to your AWS configuration directory.

    docker run --rm -it -v ~/.aws:/home/node/.aws glima-devops/aws-azure-sso

The Docker image is configured with an entrypoint so you can just feed any arguments in at the end.

You can also put the docker-launch.sh script into your bin directory for the aws-azure-sso command to function as usual:

    sudo curl -o /usr/local/bin/aws-azure-sso https://raw.githubusercontent.com/glima-devops/aws-azure-sso/main/docker-launch.sh -L
    sudo chmod o+x /usr/local/bin/aws-azure-sso

Now just run `aws-azure-sso`.

### Snap

https://snapcraft.io/aws-azure-sso

## Usage

### Configuration

#### AWS

To configure the aws-azure-sso client run:

    aws-azure-sso --configure

You'll need your [Azure Tenant ID and the App ID URI](#getting-your-tenant-id-and-app-id-uri). To configure a named profile, use the --profile flag.

    aws-azure-sso --configure --profile foo

##### GovCloud Support

To use aws-azure-sso with AWS GovCloud, set the `region` profile property in your ~/.aws/config to the one of the GovCloud regions:

- us-gov-west-1
- us-gov-east-1

##### China Region Support

To use aws-azure-sso with AWS China Cloud, set the `region` profile property in your ~/.aws/config to the China region:

- cn-north-1

#### Staying logged in, skip username/password for future logins

During the configuration you can decide to stay logged in:

    ? Stay logged in: skip authentication while refreshing aws credentials (true|false) (false)

If you set this configuration to true, the usual authentication with username/password/MFA is skipped as it's using session cookies to remember your identity. This enables you to use `--no-prompt` without the need to store your password anywhere, it's an alternative for using environment variables as described below.
As soon as you went through the full login procedure once, you can just use:

    aws-azure-sso --no-prompt

or

    aws-azure-sso --profile foo --no-prompt

to refresh your aws credentials.

#### Environment Variables

You can optionally store your responses as environment variables:

- `AZURE_TENANT_ID`
- `AZURE_APP_ID_URI`
- `AZURE_DEFAULT_USERNAME`
- `AZURE_DEFAULT_PASSWORD`
- `AZURE_DEFAULT_ROLE_ARN`
- `AZURE_DEFAULT_DURATION_HOURS`

To avoid having to `<Enter>` through the prompts after setting these environment variables, use the `--no-prompt` option when running the command.

    aws-azure-sso --no-prompt

> **Behaviour change in v3.7.0.** `--no-prompt` used to be stuck on: a bug in the option definition meant the tool never prompted, whether or not you passed the flag. It now does what it says. If you were relying on the old behaviour without passing the flag — for example in a cron job — add `--no-prompt` explicitly.

Use the `HISTCONTROL` environment variable to avoid storing the password in your bash history (notice the space at the beginning):

    $ HISTCONTROL=ignoreboth
    $  export AZURE_DEFAULT_PASSWORD=mypassword
    $ aws-azure-sso

### Logging In

Once aws-azure-sso is configured, you can log in. For the default profile, just run:

    aws-azure-sso

You will be prompted for your username and password. If MFA is required you'll also be prompted for a verification code or mobile device approval. To log in with a named profile:

    aws-azure-sso --profile foo

Alternatively, you can set the `AWS_PROFILE` environmental variable to the name of the profile just like the AWS CLI.

Once you log in you can use the AWS CLI or SDKs as usual!

If you are logging in on an operating system with a GUI, you can log in using the actual Azure web form instead of the CLI:

    aws-azure-sso --mode gui

Logging in with GUI mode is likely to be much more reliable.

_Note:_ on virtual machines, or when rendering of the puppeteer UI fails, you might need to disable the GPU Hardware Acceleration:

    aws-azure-sso --mode gui --disable-gpu

_Note:_ on Linux you will likely need to disable the Puppeteer sandbox or Chrome will fail to launch:

    aws-azure-sso --no-sandbox

> **Security:** `--no-sandbox` removes Chromium's process isolation. Only use it when required (typically Linux servers/CI without a user namespace). On desktop Linux, try running without it first.

### Behind corporate proxy

If behind corporate proxy, then just set https_proxy env variable.

## Automation

### Renew credentials for all configured profiles

You can renew credentials for all configured profiles in one run. This is especially useful, if the maximum session length on AWS side is configured to a low value due to security constraints. Just run:

    aws-azure-sso --all-profiles

If you configure all profiles to stay logged in, you can easily skip the prompts:

    aws-azure-sso --all-profiles --no-prompt

This will allow you to automate the credentials refresh procedure, eg. by running a cronjob every 5 minutes.
To skip unnecessary calls, the credentials are only getting refreshed if the time to expire is lower than 11 minutes.

## Security Considerations

### Storing passwords (azure_default_password)

**Do not store your Azure password in `~/.aws/config` or as the `AZURE_DEFAULT_PASSWORD` environment variable unless you understand the risks.**

Both locations store the password in plaintext. Anyone with read access to the file or the process environment can retrieve it. The tool will warn you at runtime when a stored password is detected.

Safer alternatives that avoid storing passwords:

- Turn on "Stay logged in" in `--configure` (stores session cookies instead of a password — see [Staying logged in](#staying-logged-in-skip-usernamepassword-for-future-logins)). There is no `--remember-me` flag; the setting lives in `~/.aws/config` as `azure_default_remember_me`.
- Enter the password interactively each time
- Use a secrets manager (e.g. `pass`, macOS Keychain, Windows Credential Manager) and inject the value only at runtime

### --no-verify-ssl

The `--no-verify-ssl` flag disables TLS certificate verification for calls to the AWS STS API. This makes the connection vulnerable to Man-in-the-Middle (MITM) attacks: an attacker on the same network could intercept the SAML response and steal your temporary AWS credentials.

**Only use this flag on isolated, fully trusted networks where you control all traffic.** The tool prints a warning when this flag is active.

### Choosing the browser (`--browser`, `--browser-profile`)

By default the tool auto-detects an installed browser (**Edge first** — since this tool targets Azure AD SSO — with Chrome as fallback). You can pick one explicitly:

```bash
# Prefer Microsoft Edge
aws-azure-sso --browser edge

# Prefer Google Chrome
aws-azure-sso --browser chrome
```

**Why Edge?** On a Windows machine joined to Azure AD (or AAD-registered), Microsoft Edge can sign you in to Azure SSO automatically via the **Primary Refresh Token (PRT)** issued by the Windows Web Account Manager — no password, no MFA prompt, no cookies needed. If you have already signed into any Microsoft app on the machine (Teams, Outlook, Office, Edge itself), `aws-azure-sso --browser edge` typically completes login with a single click. Chrome can match this behavior only with the [Microsoft Single Sign-On extension](https://chromewebstore.google.com/detail/microsoft-single-sign-on/ppnbnpeolgkicgegkbkbjmhlideopiji) installed and `--enable-chrome-seamless-sso`.

You can persist your choice per profile (it is asked by `--configure` and stored as `azure_browser` in `~/.aws/config`).

#### Reusing an existing browser session (`--browser-profile`)

If you are on a machine that is **not** Azure AD-joined but you are already signed in to your Microsoft account inside Edge/Chrome, you can reuse that session by pointing the tool at your browser's User Data directory:

```bash
# Windows (PowerShell)
aws-azure-sso --browser edge --browser-profile "$env:LOCALAPPDATA\Microsoft\Edge\User Data"

# macOS
aws-azure-sso --browser edge --browser-profile "$HOME/Library/Application Support/Microsoft Edge"

# Linux
aws-azure-sso --browser edge --browser-profile "$HOME/.config/microsoft-edge"
```

> **The browser must be fully closed** — Edge/Chrome locks the User Data directory while running and the launch will fail otherwise.

> **Security:** this gives `aws-azure-sso` access to all cookies and sessions in that profile. Prefer `--browser edge` on AAD-joined Windows (no profile access needed) when possible.

The value can also be persisted per profile as `azure_browser_profile` via `--configure`.

### If the browser fails to start

On some Windows installs of Edge, `msedge.exe` detaches and exits immediately,
and Puppeteer reports:

```
Failed to launch the browser process:  Code: 0
```

A working browser actually did come up — Puppeteer just gave up on the child
process it spawned. The tool detects this and automatically falls back to
starting the browser detached and attaching over its DevTools port, printing:

```
⚠️  Could not start the browser the usual way; attaching over its DevTools port instead.
```

This is handled for you and the login proceeds normally. If the fallback also
fails, close the browser completely — including background processes, which on
Windows survive closing every window (`Get-Process msedge | Stop-Process`) —
and try again.

### Custom browser path (PUPPETEER_EXECUTABLE_PATH)

This fork uses `puppeteer-core` instead of the bundled Chromium, relying on a browser already installed on your machine. You can override the browser path with:

```bash
export PUPPETEER_EXECUTABLE_PATH="/path/to/chrome"
```

The path is validated at startup: it must be an absolute path to an existing file. If it does not exist or is not absolute, the tool exits with a clear error. If the variable is not set, the tool searches known installation paths for Chrome, Chromium, and Edge on Windows, macOS, and Linux (filtered by `--browser` when specified).

### Protecting ~/.aws/config and ~/.aws/credentials

AWS credentials and session tokens are stored in plaintext by the AWS CLI convention.

**On Linux and macOS**, aws-azure-sso automatically writes `~/.aws/config` and `~/.aws/credentials` with mode `0600` (owner read/write only) since v3.6.6. No manual `chmod` needed.

Since v3.7.0 the permissions are also re-applied to files that already existed, so a `~/.aws/credentials` left at `0644` by the AWS CLI gets locked down on the next login. (`fs.writeFile`'s `mode` only applies when it creates the file, which is why older versions could not repair an existing one.) To check:

```bash
ls -l ~/.aws/config ~/.aws/credentials
```

**On Windows**, ensure the files are not synced to shared locations (OneDrive, network drives) without encryption.

## Getting Your Tenant ID and App ID URI

Your Azure AD system admin should be able to provide you with your Tenant ID and App ID URI. If you can't get it from them, you can scrape it from a login page from the myapps.microsoft.com page.

1. Load the myapps.microsoft.com page.
2. Click the chicklet for the login you want.
3. In the window the pops open quickly copy the login.microsoftonline.com URL. (If you miss it just try again. You can also open the developer console with nagivation preservation to capture the URL.)
4. The GUID right after login.microsoftonline.com/ is the tenant ID.
5. Copy the SAMLRequest URL param.
6. Paste it into a URL decoder ([like this one](https://www.samltool.com/url.php)) and decode.
7. Paste the decoded output into the a SAML deflated and encoded XML decoder ([like this one](https://www.samltool.com/decode.php)).
8. In the decoded XML output the value of the `Audience` tag is the App ID URI.
9. You may double-check tenant ID using `Attribute` tag named `tenantid` provided in XML.

## How It Works

The Azure login page uses JavaScript, which requires a real web browser. To automate this from a command line, aws-azure-sso uses [`puppeteer-core`](https://pptr.dev) to drive a browser **already installed on your machine** (Edge, Chrome or Chromium) — no Chromium is bundled or downloaded. It loads the Azure login page behind the scenes, populates your username and password (and MFA token), parses the SAML assertion, uses the [AWS STS AssumeRoleWithSAML API](http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithSAML.html) to get temporary credentials, and saves these in the CLI credentials file.

## Troubleshooting

The nature of browser automation with Puppeteer means the solution is bit brittle. A minor change on the Microsoft side could break the tool. If something isn't working, you can fall back to GUI mode (above). To debug an issue, you can run in debug mode (--mode debug) to see the GUI while aws-azure-sso tries to populate it. You can also have the tool print out more detail on what it is doing to try to do in order to diagnose. aws-azure-sso uses the [Node debug module](https://www.npmjs.com/package/debug) to print out debug info. Just set the DEBUG environmental variable to `aws-azure-login` (the namespace kept its original name through the rename, so it is *not* `aws-azure-sso`). On Linux/OS X:

    DEBUG=aws-azure-login aws-azure-sso

On Windows:

    set DEBUG=aws-azure-login
    aws-azure-sso

The debug output never contains the SAML assertion or your password. It does include your username and tenant, so skim it before pasting it into an issue.

## Maintaining this fork

For whoever picks this up next, including future you. The traps below are the ones that actually bit, not hypotheticals.

### Ground rules

- **npm only.** `yarn.lock` was deliberately deleted. CI, Docker, snapcraft and CONTRIBUTING all use `npm ci`. Carrying two lockfiles meant the tree CI installed and the tree `npm audit` analysed could drift apart silently.
- **`lib/` is a build artifact.** It is gitignored and built by CI on release. Never commit it, and remember it is what `bin` points at — a stale `lib/` means your fixes are not in the published package even though they are in `src/`.
- **Never hand-write a `.d.ts` for a dependency.** A `typings/proxy-agent/index.d.ts` describing the v4 API survived the upgrade to v6, so `tsc` happily validated `proxy(url)` against a package that had replaced that function with a class. Proxy support was broken for months with a green build. If a package's own types do not resolve, fix the resolution, do not fake the types.

### Updating dependencies

```bash
npm outdated
npm audit
npm update                 # semver-compatible
npm install <pkg>@latest   # for a major, one at a time
```

Then, every time:

```bash
npm test          # eslint + prettier
npm run build     # tsc
node lib/index.js --help    # smoke test — see below
```

**Judge reachability before chasing an advisory.** `npm audit` reports the whole tree, not what the code executes. `basic-ftp` is pinned through an `overrides` entry rather than by downgrading `proxy-agent`, because `get-uri` only touches it to fetch `ftp://` PAC files — a path this tool never takes. The fix npm suggested would have reintroduced a crash.

**Watch the Node floor.** `puppeteer-core`, `uuid` and `proxy-agent` are ESM-only and are `require()`d from CommonJS, which needs a Node that supports `require(esm)` — hence `engines.node >= 20.19`. `tsconfig.json` uses `"module": "node20"` so TypeScript models that accurately; it also requires TypeScript >= 5.9. If you drop that setting, module resolution silently stops reading `exports` maps, which is how the proxy bug hid.

### Verifying a change

Lint and `tsc` never load the dependencies, so they cannot catch an `ERR_REQUIRE_ESM`, a broken default import or a renamed export. **Always start the built CLI.** CI does this on Node 20, 22 and 24; do it locally too:

```bash
npm run build && node lib/index.js --help
```

Before a release, also drive a real browser — the login loop is the part that breaks:

```bash
DEBUG=aws-azure-login aws-azure-sso --mode debug --profile <your-profile>
```

### Releasing

1. Bump `version` in `package.json`.
2. Push to `main`; the Main workflow runs the matrix.
3. Tag and push the tag — the Release workflow builds `lib/`, publishes to npm, Docker Hub and the Snap Store.

Secrets used: `NPM_TOKEN`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `SNAPCRAFT_STORE_LOGIN`.

> **Known risk:** the Docker publish step uses `elgohr/Publish-Docker-Github-Action@master` — a third-party action with no commit pin, running with those secrets. Pinning it to a specific commit SHA is worth doing.

### Syncing with upstream

`origin` points at the **upstream** project and `sso` at this fork. Pushing this branch to `origin` would target `aws-azure-login/aws-azure-login`, not your own repo.

```bash
git fetch origin
git merge origin/main        # or rebase
npm ci && npm test && npm run build && node lib/index.js --help
git push sso <branch>
```

Expect conflicts in `src/login.ts` and `package.json`: this fork diverges there the most (browser selection, the DevTools-port fallback, the security fixes).

## Support for Other Authentication Providers

Obviously, this tool only supports Azure AD as an identity provider. However, there is a lot of similarity with how other logins with other providers would work (especially if they are SAML providers). If you are interested in building support for a different provider let me know. It would be great to build a more generic AWS CLI login tool with plugins for the various providers.
