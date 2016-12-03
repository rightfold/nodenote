module NN.Client.Vertex.DSL
( VertexDSL
, VertexDSLF(..)
, getVertex
, vertexBus
, newVertex
) where

import Control.Monad.Aff.Bus (BusRW)
import Control.Monad.Free (Free, liftF)
import NN.File (FileID)
import NN.Prelude
import NN.Vertex (Vertex, VertexID)

type VertexDSL = Free VertexDSLF

data VertexDSLF a
    = GetVertex VertexID (Maybe Vertex -> a)
    | VertexBus (BusRW (Tuple VertexID Vertex) -> a)
    | NewVertex FileID (List VertexID) (VertexID -> a)

getVertex :: VertexID -> VertexDSL (Maybe Vertex)
getVertex vertexID = liftF $ GetVertex vertexID id

vertexBus :: VertexDSL (BusRW (Tuple VertexID Vertex))
vertexBus = liftF $ VertexBus id

newVertex :: FileID -> List VertexID -> VertexDSL VertexID
newVertex fileID parents = liftF $ NewVertex fileID parents id
