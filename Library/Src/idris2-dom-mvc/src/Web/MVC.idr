module Web.MVC

import Data.IORef
import Data.Queue

import public JS
import public Web.MVC.Cmd
import public Web.MVC.View
import public Text.HTML

||| Run (a part of) an interactive web page firing events of type
||| `e` and holding state of type `s`.
export covering
runController :
     {s      : Type}
  -> (0 e    : s -> Type)
  -> (ctrl   : (stOld : s) -> e stOld -> (stNew : s ** Cmd (e stNew)))
  -> (onErr  : JSErr -> IO ())
  -> (initST : s)
  -> (initEv : e initST)
  -> IO ()
runController e ctrl onErr initST initEv = Prelude.do
  flag  <- newIORef False
  queue <- newIORef $ Queue.empty {a = (st : s ** e st)}

  let covering handle : (st : s) -> e st -> IO ()
      handle st ev = Prelude.do

        -- Enqueue synchronously fired events if we are already handling
        -- an event
        False <- readIORef flag | True => modifyIORef queue (`enqueue` (st ** ev))

        -- Start handling the event and prevent others from currently
        -- being handled
        writeIORef flag True

        -- compute new application state and the command to run
        let (stNew ** cmd) := ctrl st ev

        -- run the command by invoking it with this very event handler
        -- the command might fire one or more events synchronously. these
        -- will be enqueued and processed in a moment.
        ei <- runEitherT (run cmd (liftIO . handle stNew))

        case ei of
          Left err => onErr err
          Right () => pure ()

        -- we are done with handling the current event so we set the flag
        -- back to false.
        writeIORef flag False

        -- we are now going to process the next enqueued command (if any)
        Just ((st2 ** ev2),q) <- dequeue <$> readIORef queue | Nothing => pure ()
        writeIORef queue q
        handle st2 ev2

  handle initST initEv

export covering
runMVC :
     {s       : Type}
  -> (0 e     : s -> Type)
  -> (update  : (st : s) -> e st -> s)
  -> (display : (st : s) -> (ev : e st) -> Cmd (e (update st ev)))
  -> (onErr   : JSErr -> IO ())
  -> (initST  : s)
  -> (initEv  : e initST)
  -> IO ()
runMVC e upd disp onErr =
  runController e (\st,ev => (upd st ev ** disp st ev)) onErr
