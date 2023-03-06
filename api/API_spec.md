# API Spec

This readme is based on: 
https://github.com/J22Melody/signwriting-translation/blob/main/API_spec.md written by Zifan Jiang.

All parameters are optional.

`POST /api/translate`

requests

```
{
    "source_language_code": "de",
    "target_language_code": "dgs",
    "text": "Das ist ein Test."
}
```

returns

```
{
    "n_best": 3,
    "source_language_code": "de",
    "target_language_code": "dgs",
    "text": "Das ist ein Test.",
    "translations": [
        " $num-einer1 $num-einer1 $num-zehner2 $index1 tinnitus1",
        " $num-einer1 $num-einer1 $num-zehner2",
        " $num-einer1 $num-einer1 $num-zehner2 $index1 treiben1"
    ]
}
```
