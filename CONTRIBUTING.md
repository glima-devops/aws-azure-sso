# Contributing

## Get started

This project is written in TypeScript and is using prettier and eslint for code formatting. You need node v22 or newer (v20.19 is the bare minimum: the ESM-only dependencies require a Node that can require() an ES module).

1. Install node v22. I recommend installing that with nvm: https://github.com/nvm-sh/nvm

```sh
nvm install 22
```

2. Make node v22 default

```sh
nvm alias default 22
```

3. Open a new terminal and verify node version (should return v22.X.X or newer)

```sh
node -v
```

4. Fork and clone project

```sh
git clone git@github.com:<GITHUB_USERNAME>/aws-azure-login.git
cd aws-azure-login
```

5. Install dependencies

```sh
npm ci
```

6a. Start dev mode

```sh
npm start
```

6b. Start prod mode

```sh
npm run build && node ./lib/index.js
```
