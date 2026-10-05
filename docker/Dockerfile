FROM haskell:9.6
WORKDIR /opt/payroute
COPY . .
RUN cabal update && cabal build
EXPOSE 8080
CMD ["cabal","run","payroute"]
