module.exports = {
  root: true,
  env: {
    es6: true,
    node: true
  },
  parserOptions: {
    "ecmaVersion": 8
  },
  extends: [
    "eslint:recommended",
    "google"
  ],
  rules: {
    "quotes": ["error", "double"],
    "max-len": ["error", {"code": 160}],
    "comma-dangle": ["error", "never"],
    "linebreak-style": ["error", "windows"]
  }
};
