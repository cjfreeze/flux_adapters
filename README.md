# FluxAdapters

A temporary repo for various adapters and helpers that allow `flux` to interact with `plug` and `phoenix`.

Because the Plug adapter was removed from flux, I can no longer cheat and call it directly when calling the phoenix endpoint, so for now I added a temporary optional config option `:plug_adapter` to `flux` which should be set in the phoenix project to `FluxAdapters.Plug`.

Getting channels to work with phoenix with this library is also possible and surprisingly not that hard but I will detail that later.

