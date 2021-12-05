FROM alpine:latest
    
RUN  mkdir /tmp/pro-flask/

WORKDIR /tmp/pro-flask/

COPY ./project/  .

RUN apk update && apk add --no-cache python3 && apk add --no-cache py-pip

RUN pip install -r requirements.txt

EXPOSE 8081

CMD [ "python3" , "app.py"]
