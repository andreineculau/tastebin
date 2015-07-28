pkg = require './package.json'
phonetic = require 'phonetic'

module.exports = {
  # backend-only vars
  pkg
  listenOn: [
    protocol: 'http'
    module: 'http'
    hostname: '0.0.0.0'
    port: 3000
    options: undefined     # options for module.createServer
    headers:               # extra headers
      'Cache-Control': 'no-cache, no-store, must-revalidate'
      'Pragma': 'no-cache'
      'Expires': '0'
      'Server': "#{pkg.name}/#{pkg.version}"
  ],
  subpath: '/'             # host tastebin under a subpath
  tastesDir: 'tastes'      # where are tastes stored
  maxListCount: 100        # list only the most recent 100 tastes
  maxSize: '128kb'         # allow only tastes smaller than 128 kilobytes
  maxFilenameLength: 256   # allow tastes to have maximum 256 characters
  maxLifetimeCount: 500    # keep no more than the most recent 500 tastes
  maxLifetimeDays: 12 * 30 # keep tastes created withing the last 360 days
  maxLifetimeIgnoreFiles: [
    '.gitignore'
  ]
  generate: () ->          # function to generate random names
    phonetic.generate {syllables: 10, capFirst: false}
  morgan:                  # logging https://github.com/expressjs/morgan
    format: 'common'

  # backend & frontend vars
  title: "#{pkg.name}/#{pkg.version}"
  newTaste: [              # content for the "new taste" page
    'A. Double click to start editing'
    'B. \#{metaKeyName}+S to Save'
    '   \#{metaKeyName}+Shift+S to Save As'
    '   Save As with a leading dot to hide'
    'C. Esc to cancel editing'
  ].join '\n'
  stylesheets: ''             # extra stylesheets
  scripts: ''                 # extra scripts
  theme: 'index'              # default theme
  themes: [                   # available themes
    'index'
    'distraction-free'
  ]
  hljsStyle: 'solarized_dark' # default style
  hljsStyles: [               # available styles
    'agate'
    'androidstudio'
    'arta'
    'ascetic'
    'atelier-cave.dark'
    'atelier-cave.light'
    'atelier-dune.dark'
    'atelier-dune.light'
    'atelier-estuary.dark'
    'atelier-estuary.light'
    'atelier-forest.dark'
    'atelier-forest.light'
    'atelier-heath.dark'
    'atelier-heath.light'
    'atelier-lakeside.dark'
    'atelier-lakeside.light'
    'atelier-plateau.dark'
    'atelier-plateau.light'
    'atelier-savanna.dark'
    'atelier-savanna.light'
    'atelier-seaside.dark'
    'atelier-seaside.light'
    'atelier-sulphurpool.dark'
    'atelier-sulphurpool.light'
    'brown_paper'
    'codepen-embed'
    'color-brewer'
    'dark'
    'darkula'
    'default'
    'docco'
    'far'
    'foundation'
    'github-gist'
    'github'
    'googlecode'
    'hybrid'
    'idea'
    'ir_black'
    'kimbie.dark'
    'kimbie.light'
    'magula'
    'mono-blue'
    'monokai'
    'monokai_sublime'
    'obsidian'
    'paraiso.dark'
    'paraiso.light'
    'pojoaque'
    'railscasts'
    'rainbow'
    'school_book'
    'solarized_dark'
    'solarized_light'
    'sunburst'
    'tomorrow-night-blue'
    'tomorrow-night-bright'
    'tomorrow-night-eighties'
    'tomorrow-night'
    'tomorrow'
    'vs'
    'xcode'
    'zenburn'
  ]
}
