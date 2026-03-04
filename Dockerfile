FROM alpine:latest

COPY . /dotfiles
WORKDIR /dotfiles

CMD ["./deploy.sh"]
