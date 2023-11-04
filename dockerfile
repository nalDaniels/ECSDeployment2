FROM python:3.7
RUN git clone https://github.com/nalDaniels/ECSDeployment.git
WORKDIR ECSDeployment
RUN pip install -r requirements.txt
RUN pip install gunicorn
RUN pip install mysqlclient
RUN python database.py
RUN python load_data.py
EXPOSE 8000
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0", "app:app"]
