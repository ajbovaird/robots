# An Elm-lang  Implementation of Robots

This is my go at the 'Robots' problem, which I've used as a kata to learn [Elm](https://guide.elm-lang.org/), a functional language that compiles to JavaScript. 

The general gist of Elm programs (using The Elm Architecture) is an implementation of a pattern known as Model-View-Update. The 'view' function returns HTML rendered through Elm's virtual DOM. The 'model' function stores the entire application state. The 'update' function recieves a 'Msg' union type and the current model state, and performs a pattern match on the 'Msg' in order to mutate and process the application state. 

My implementation is a single 'robots.elm' file. Comments are used to "section off" the program as follows:
* TYPES - definitions of all of the type aliases, and some helper record types to make things a little more readable.
* MODEL - the application state record and initialization function
* UPDATE - definitions for the 'Msg' union type and the update function
* SUBSCRIPTIONS - unused boilerplate to keep the Elm compiler happy
* VIEW - view function that uses an HTML-like DSL, and a few helper functions to keep things DRY
* DOMAIN - the business logic of the application, called by the 'update' function to do work on the application state

The main data structure in the application is `World`, which is an array of `PlaceInWorld` elements. Each `PlaceInWorld` represents a tuple `(House, List PlaceInWorld, Presents)`.

# Requirements

1. Install Elm -> [https://guide.elm-lang.org/install.html](https://guide.elm-lang.org/install.html)
2. Clone this repo.
3. Run the 'elm-reactor' command line tool from the root directory
4. Browse to [http://localhost:8000/robots.elm](http://localhost:8000/robots.elm)
