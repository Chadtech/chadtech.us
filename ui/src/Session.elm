module Session exposing
    ( Session
    , goTo
    , init
    , setAdminPassword
    )

import Browser.Navigation as Nav
import Route exposing (Route)



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type alias Session =
    { navKey : Nav.Key
    , adminPassword : String
    }



---------------------------------------------------------------
-- INIT --
---------------------------------------------------------------


init : Nav.Key -> Session
init navKey =
    { navKey = navKey
    , adminPassword = ""
    }



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


setAdminPassword : String -> Session -> Session
setAdminPassword str session =
    { session | adminPassword = str }


goTo : Session -> Route -> Cmd msg
goTo session route =
    Nav.pushUrl session.navKey (Route.toString route)
