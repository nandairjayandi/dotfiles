FROM alpine:latest

COPY . /dotfiles
WORKDIR /dotfiles

CMD ["./bootstrap.sh"]
