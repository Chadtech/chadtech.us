module Session exposing
    ( Session
    , goTo
    , init
    )

import Browser.Navigation as Nav
import Route exposing (Route)



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type alias Session =
    { navKey : Nav.Key }



---------------------------------------------------------------
-- INIT --
---------------------------------------------------------------


init : Nav.Key -> Session
init navKey =
    { navKey = navKey }



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


goTo : Session -> Route -> Cmd msg
goTo session route =
    Nav.pushUrl session.navKey (Route.toString route)
