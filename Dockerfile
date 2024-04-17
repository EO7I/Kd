FROM ubuntu
RUN apt-get update && apt-get install -y -q nginx
COPY index.html /var/www/html/
CMD ["nginx", "-g", "daemon off; " ]
