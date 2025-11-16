export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'build',    // Changes to build system or dependencies
        'chore',    // Other changes that don't modify src or test files
        'ci',       // Changes to CI configuration files and scripts
        'docs',     // Documentation only changes
        'feat',     // A new feature
        'fix',      // A bug fix
        'perf',     // Performance improvements
        'refactor', // Code changes that neither fix a bug nor add a feature
        'revert',   // Reverts a previous commit
        'style',    // Code style changes (formatting, missing semi-colons, etc)
        'test',     // Adding or updating tests
      ],
    ],
    'subject-case': [2, 'never', ['start-case', 'pascal-case', 'upper-case']],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'scope-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 100],
  },
};
