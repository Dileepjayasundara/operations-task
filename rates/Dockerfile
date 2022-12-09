FROM python:alpine3.17

#RUN pip install -U pip && adduser -D appuser
RUN adduser -D appuser

USER appuser

WORKDIR /app

COPY --chown=appuser:appuser . /app/

RUN pip install --user -U gunicorn && pip install --user -Ur requirements.txt

ENV PATH="/home/appuser/.local/bin:${PATH}"

EXPOSE 3000

ENTRYPOINT ["gunicorn" , "wsgi"]

CMD ["-b", "0.0.0.0:3000"]
