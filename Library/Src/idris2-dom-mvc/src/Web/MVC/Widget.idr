module Web.MVC.Widget

import Web.MVC

%default total

--------------------------------------------------------------------------------
--          Widgets
--------------------------------------------------------------------------------


||| A `Widget` is a standalone UI element that manages its own
||| state. It packages up all aspects of an MVC component into a
||| single piece of data that can be passed around and transformed,
||| before finally turned into a runnable program with `runWidget`.
|||
||| See the various parameters of `Web.MVC.runMVC` for further
||| explanation.
public export
record Widget where
  constructor MkWidget

  ||| The internal state of the widget (model)
  St : Type
  ||| Event type
  0 Ev : St -> Type
  ||| Initial state
  init : St
  ||| Given the initial state, set up the  UI
  setup : (st : St) -> Cmd (Ev st)
  ||| Update the state based on the latest event
  update : (st : St) -> Ev st -> St
  ||| Update the UI based on the latest event and the current state
  display : (st : St) -> (ev : Ev st) -> Cmd (Ev (update st ev))

||| `w1 <+> w2` is the independent composition of widgets `w1` and
||| `w2`, with the product state and the sum events.
public export
Semigroup Widget where
  w1 <+> w2 = MkWidget
    { St = (w1.St, w2.St)
    , Ev = \(st1, st2) => Either (w1.Ev st1) (w2.Ev st2)
    , init = (w1.init, w2.init)
    , setup = \(s1, s2) => batch
        [ Left <$> w1.setup s1
        , Right <$> w2.setup s2
        ]
    , update = \(s1, s2), ev => case ev of
        Left  ev1 => (w1.update s1 ev1, s2)
        Right ev2 => (s1, w2.update s2 ev2)
    , display = \(s1, s2), ev => case ev of
        Left ev  => Left <$> w1.display s1 ev
        Right ev => Right <$> w2.display s2 ev
    }

||| `neutral` is the trivial widget with trivial state and no events
public export
Monoid Widget where
  neutral = MkWidget
    { St = ()
    , Ev = \_ => Void
    , init = ()
    , setup = neutral
    , update = \_ => absurd
    , display = \_, _ => neutral
    }

||| Run a `Widget`. This is basically `runMVC` with the arguments
||| constructed from the fields of `Widget`. Since this function
||| produces no result, there's no going back from here: all `Widget`
||| composition and transformation must be done beforehand.
export
covering
runWidget : (JSErr -> IO ()) -> Widget -> IO ()
runWidget onError w = runMVC (Maybe . w.Ev) update display onError w.init Nothing
  where
    update : (st : w.St) -> Maybe (w.Ev st) -> w.St
    update st Nothing = st
    update st (Just ev) = w.update st ev

    display : (st : w.St) -> (ev : Maybe (w.Ev st)) -> Cmd (Maybe (w.Ev (update st ev)))
    display st Nothing = Just <$> w.setup st
    display st (Just ev) = Just <$> w.display st ev
