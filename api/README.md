# gloss translation API

## Setup (do these steps only the first time)

Clone this repository, move into sub-directory:

    git clone https://github.com/bricksdont/easier-gloss-translation.git
    cd easier-gloss-translation/api

Install conda if not installed, for instance like this:

    wget https://repo.anaconda.com/archive/Anaconda3-2022.10-Linux-x86_64.sh

Create env (Anaconda must be installed):

    ./create_api_env.sh

For all subsequent steps, the conda env must be activated.

Install sentencepiece with admin privileges:

    sudo apt install sentencepiece

Download models here:

    ./download_models.sh

## Start local server

Then run server, instructions are based on: https://github.com/J22Melody/signwriting-translation#api-server:

Run [Flask](https://flask.palletsprojects.com/) locally for debugging:

`python app.py`

## Deployment

Run with [Gunicorn](https://gunicorn.org/) for deployment. Install with pip, for example:

    pip install gunicorn

Then

`gunicorn -w 4 -b 0.0.0.0:3030 app:app`

Example [Supervisor](http://supervisord.org/) config file (`/etc/supervisor/conf.d/gunicorn.conf`):

```
[program:gunicorn]
user=xxx
directory=/home/xxx/easier-gloss-translation/api
command=gunicorn -w 4 -b 0.0.0.0:3030 app:app

autostart=true
autorestart=true
stdout_logfile=/home/xxx/log/gunicorn.log
stderr_logfile=/home/xxx/log/gunicorn.err.log
```

See [API_spec.md](https://github.com/J22Melody/signwriting-translation/blob/main/API_spec.md) for API specifications.
