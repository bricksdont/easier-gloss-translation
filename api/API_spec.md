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
    "text": "Das ist ein Test"
}
```

returns

```
{
    "n_best": 3,
    "source_language_code": "de",
    "target_language_code": "dgs",
    "text": "Das ist ein Test",
    "translations": [
        "Test2",
        "Test1",
        "Test3"
    ]
}
```
