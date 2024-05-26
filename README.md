# dcape-app-powerdns

> Приложение ядра [dcape](https://github.com/dopos/dcape) для предоставления сервиса DNS.

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-powerdns.svg
[2]: https://github.com/dopos/dcape-app-powerdns/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-powerdns.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-powerdns.svg
[5]: LICENSE

 Роль в dcape | Сервис | Docker images
 --- | --- | ---
 ns | [PowerDNS](https://www.powerdns.com/) | [ghcr.io/dopos/powerdns-alpine](https://github.com/dopos/powerdns-alpine)

## Назначение

* Wildcard-DNS для сертификатов LetsEncrypt
* Сервис DNS

Сервис может быть развернут как отдельное приложение dcape.

---

## Install

Приложение разворачивается в составе [dcape](https://github.com/dopos/dcape).

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017-2024 Aleksei Kovrizhkin <lekovr+dopos@gmail.com>
