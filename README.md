# Tastebin

A pastebin with taste i.e. minimalistic

* server: NodeJS, CoffeeScript, ExpressJS, ...
* client: HTML5, CoffeeScript, HighlightJs, ...

![New](SEEME.png)
![Edit](SEEME2.png)
![Share](SEEME3.png)

## Demo link

A friend of mine fired it up at http://tastebin.x-berg.de/ . Thanks, [Stefan](https://github.com/sstrigler)! :)

## Install and run

```sh
git clone git://github.com/andreineculau/tastebin.git
cd tastebin
npm install
# edit config.coffee as you see fit
npm start
```

## Tested browsers

* Chrome 44

## Shell with curl/httpie

```sh
export TASTEBIN_URL="http://localhost:3000"
source tastebin.curl.sh # or tastebin.httpie.sh

# Save taste
echo "foo" | tastebin_save

# Save taste as...
echo "foo" | tastebin_save_as mynewtaste
```

## License

[Apache 2.0](LICENSE)
