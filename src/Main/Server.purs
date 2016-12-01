module Main.Server
( main
) where

import Control.Coroutine (emit)
import Control.Monad.Aff (launchAff)
import Control.Monad.Eff.Unsafe (unsafePerformEff)
import Data.Map (Map)
import Data.Map as Map
import Data.Sexp as Sexp
import Data.String as String
import Data.String.CaseInsensitive (CaseInsensitiveString(..))
import Data.UUID (GENUUID)
import Database.PostgreSQL (newPool, Pool, POSTGRESQL, withConnection)
import Network.HTTP.Message (Request, Response)
import Network.HTTP.Node (nodeHandler)
import Node.Buffer as Buffer
import Node.Encoding (Encoding(UTF8))
import Node.FS (FS)
import Node.FS.Sync (readFile)
import Node.HTTP (createServer, listen)
import NN.Prelude
import NN.Server.Setup (setupDB)
import NN.Server.Vertex.DB as Vertex.DB
import NN.Vertex (VertexID(..))

main = launchAff do
    db <- newPool { user: "postgres"
                  , password: "lol123"
                  , host: "localhost"
                  , port: 5432
                  , database: "nn"
                  , max: 10
                  , idleTimeoutMillis: 0
                  }

    withConnection db setupDB

    liftEff do
        server <- createServer $ nodeHandler $ handle db
        listen server {hostname: "localhost", port: 1337, backlog: Nothing} (pure unit)

handle
    :: ∀ eff
     . Pool
    -> Request (fs :: FS, uuid :: GENUUID, postgreSQL :: POSTGRESQL | eff)
    -> Aff (fs :: FS, uuid :: GENUUID, postgreSQL :: POSTGRESQL | eff) (Response (fs :: FS, uuid :: GENUUID, postgreSQL :: POSTGRESQL | eff))
handle db req =
    case String.split (String.Pattern "/") req.path of
        ["", ""] -> static "text/html" "index.html"
        ["", "output", "nn.js"] -> static "application/javascript" "output/nn.js"
        ["", "output", "nn.css"] -> static "text/css" "output/nn.css"
        ["", "api", "v1", "vertices"] -> handleCreateVertex db
        ["", "api", "v1", "vertices", vertexID] -> handleVertex db (VertexID vertexID)
        ["", "api", "v1", "vertices", parentID, "children", childID] ->
            handleCreateEdge db {parentID: VertexID parentID, childID: VertexID childID}
        _ -> pure notFound

static :: ∀ eff. String -> String -> Aff (fs :: FS | eff) (Response (fs :: FS | eff))
static mime path = do
    contents <- liftEff' $ readFile path
    pure { status: {code: 200, message: "OK"}
         , headers: Map.singleton (CaseInsensitiveString "content-type") mime
         , body: emit contents
         }

handleCreateVertex
    :: ∀ eff
     . Pool
    -> Aff (uuid :: GENUUID, postgreSQL :: POSTGRESQL | eff) (Response (uuid :: GENUUID, postgreSQL :: POSTGRESQL | eff))
handleCreateVertex db = do
    vertexID <- withConnection db Vertex.DB.createVertex
    pure { status: {code: 200, message: "OK"}
         , headers: Map.empty :: Map CaseInsensitiveString String
         , body: emit $ unsafePerformEff $ Buffer.fromString (Sexp.toString $ Sexp.toSexp vertexID) UTF8
         }

handleCreateEdge
    :: ∀ eff
     . Pool
    -> {parentID :: VertexID, childID :: VertexID}
    -> Aff (postgreSQL :: POSTGRESQL | eff) (Response (postgreSQL :: POSTGRESQL | eff))
handleCreateEdge db edge = do
    withConnection db $ Vertex.DB.createEdge `flip` edge
    pure { status: {code: 200, message: "OK"}
         , headers: Map.empty :: Map CaseInsensitiveString String
         , body: pure unit
         }

handleVertex
    :: ∀ eff
     . Pool
    -> VertexID
    -> Aff (postgreSQL :: POSTGRESQL | eff) (Response (postgreSQL :: POSTGRESQL | eff))
handleVertex db vertexID = do
    withConnection db $ Vertex.DB.readVertex `flip` vertexID
    >>= case _ of
        Just vertex ->
            pure { status: {code: 200, message: "OK"}
                 , headers: Map.empty :: Map CaseInsensitiveString String
                 , body: emit $ unsafePerformEff $ Buffer.fromString (Sexp.toString $ Sexp.toSexp vertex) UTF8
                 }
        Nothing -> pure notFound

notFound :: ∀ eff. Response eff
notFound =
    { status: {code: 404, message: "Not Found"}
    , headers: Map.empty :: Map CaseInsensitiveString String
    , body: pure unit
    }
