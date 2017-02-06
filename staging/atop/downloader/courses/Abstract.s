( function _Abstract_s_( ) {

'use strict';

// dependencies

if( typeof module !== 'undefined' )
{

  if( typeof wBase === 'undefined' )
  try
  {
    require( '../wTools.s' );
  }
  catch( err )
  {
    require( 'wTools' );
  }

  var _ = wTools;

  _.include( 'wCopyable' );
  _.include( 'wLogger' );
  _.include( 'wConsequence' );
  _.include( 'wFiles' );

}

// constructor

var _ = wTools;
var Parent = null;
var Self = function wDownloaderOfCourses( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  return o;
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'DownloaderOfCourses';

// --
// inter
// --

function init( o )
{
  var self = this;

  _.instanceInit( self );

  // if( self.Self === Self )
  Object.preventExtensions( self );

  if( o )
  self.copy( o );

  if( !self.config )
  {
    var config = require( './config.js' );

    if( !self.currentPlatform  )
    self.currentPlatform = config.defaultPlatform;

    self.config = config[ self.currentPlatform ];
  }

  _.assert( self.currentPlatform );

  if( !self._requestAct )
  self._requestAct = self.Request.defaults({ jar : true });

  if( !self._sync )
  self._sync = new wConsequence().give();

  if( !self._provider )
  self._provider = _.FileProvider.HardDrive();

}

// --
// download
// --

function download()
{
  var self = this;

  _.assert( arguments.length === 0 );

  self._sync
  .ifNoErrorThen( function()
  {
    return self._download();
  })

  return self;
}

//

function _download()
{
  var self = this;
  var con = new wConsequence().give();

  _.assert( arguments.length === 0 );

  // if( self.verbosity )
  // logger.topicUp( 'Downloading course',self.currentCourse,'..' );

  /* login */

  con.seal( self )
  .ifNoErrorThen( self._make )
  .ifNoErrorThen( self._login )
  .ifNoErrorThen( self._coursesList )
  .ifNoErrorThen( self._coursePick,[ 0 ] )
  .ifNoErrorThen( self._resourcesList )
  ;

  // con.ifNoErrorThen( function()
  // {
  //   return self._login();
  // })
  // con.ifNoErrorThen( function()
  // {
  //   return self._coursesList();
  // })
  // .ifNoErrorThen( function( courses )
  // {
  //   if( course === undefined )
  //   course = courses[ 0 ];
  //   return self._resourcesList( course );
  // })
  // .ifNoErrorThen( function( resources )
  // {
  //   return self.makeDownloadsList( resources );
  // })
  // .ifNoErrorThen( function( )
  // {
  //   console.log( _.toStr( self.downloadsList, { levels : 2 } ) );
  //   return con.give();
  // })

  con.thenDo( function( err,got )
  {
    // if( self.verbosity )
    // logger.topicDown( 'Downloading of', self.currentCourse, ( err ? 'failed' : 'done' ) + '.' );

    if( err )
    throw _.errLogOnce( err );
  });

  return self;
}

//

function clearIsDone()
{
  var self = this;
  return self.clearDone.messageHas();
}

// --
// make
// --

function make()
{
  var self = this;

  self._sync
  .ifNoErrorThen( function()
  {
    return self._make();
  });

  return self;
}

//

function _make()
{
  var self = this;

  if( !self.clearIsDone() )
  throw _.err( 'Cant make, clear is not done' );

  self.config.payload = { 'email' : self.config.email, 'password' : self.config.password };

  self.config.options =
  {
    url : self.config.loginApiUrl,
    method : 'POST',
    headers : null
  };

  self._makeAct();

  return self._makePrepareHeadersForLogin()
  .ifNoErrorThen( function()
  {
    return self.makeDone.give();
  });

}


//

function _makePrepareHeadersForLogin()
{
  var con = new wConsequence().give();
  return con;
}

//

function makeIsDone()
{
  var self = this;
  return self.makeDone.messageHas();
}

// --
// login
// --

function login()
{
  var self = this;

  self._sync
  .ifNoErrorThen( function()
  {
    return self._login();
  });

  return self;
}

//

function _login()
{
  var self = this;
  var con = new wConsequence().give();

  if( self.loginIsDone() )
  return con;

  if( !self.makeIsDone() )
  throw _.err( 'Cant login, make is not done' );

  if( self.verbosity )
  logger.topicUp( 'Login ..' );

  con.ifNoErrorThen( _.routineSeal( self,self._request,[ self.config.options ] ) )
  .thenDo( function( err,got )
  {
    if( err )
    err = _.err( err );
    // throw _.errLogOnce( err );

    if( got.response.statusCode !== 200 )
    err = _.err( "Login failed. StatusCode: ", got.response.statusCode, "Server response: ", got.body );

    if( self.verbosity )
    logger.topicDown( 'Login ' + ( err ? 'error' : 'done' ) + '.' );

    if( err )
    return con.error( err );

    var cookie = got.response.headers[ 'set-cookie' ].join( ';' );
    self.updateHeaders( 'Cookie', cookie );
    self.loginDone.give();

    return got;
  });

  return con;
}

//

function loginIsDone()
{
  var self = this;
  return self.loginDone.messageHas();
}

// --
// courses
// --

function coursesList()
{
  var self = this;

  self._sync
  .thenDo( function()
  {
    return self._coursesList();
  });

  return self;
}

//

function _coursesList()
{
  var self = this;

  if( self.coursesListIsDone() )
  return new wConsequence().give();

  if( !self.loginIsDone() )
  throw _.err( 'Cant login, login is not done' );

  if( self.verbosity )
  logger.topicUp( 'List courses ..' );

  var con = self._request( self.config.getUserCoursesUrl )
  .thenDo( function( err, got )
  {
    if( !err )
    if( got.response.statusCode !== 200 )
    {
      debugger;
      err = _.err( 'Failed to get resources list. StatusCode : ', got.response.statusCode, 'Server response : ', got.body );
    }

    if( err )
    return con.error( _.err( err ) );

    if( !self._courses )
    self._courses = [];

    return self._coursesListAct( got.body )
  })
  .thenDo( function( err,got )
  {
    self.coursesListDone.give( err,got );

    if( Config.debug )
    {
      _.each( self._courses, function( course,k,iteration )
      {
        _.assertMapHasOnly( course,self.Structure.Course );
      });
    }

    if( self.verbosity )
    {
      var log = _.toStr( got,{ levels : 3 } );
      logger.log( 'courses :' );
      logger.log( log );
      logger.log( 'courses.' );
    }

    if( self.verbosity )
    logger.topicDown( 'List courses .. ' + ( err ? 'error' : 'done' ) + '.' );

    if( err )
    throw _.errLogOnce( err );

    return got;
  });

  return con;
}

//

function _coursesListAct()
{
  var con = new wConsequence().give();
  return con;
}

//

function coursesListIsDone()
{
  var self = this;
  return self.coursesListDone.messageHas();
}

//

function course( filter )
{
  var self = this;

  _.assert( arguments.length === 1 );

  var result = _.entityFilter( self._courses, filter );

  return result;
}

//

function coursePick( src )
{
  var self = this;

  _.assert( arguments.length <= 1 );

  self._sync
  .thenDo( function()
  {
    return self._coursePick( src );
  });

  return self;
}

//

function _coursePick( src )
{
  var self = this;

  if( !src )
  src = 0;

  _.assert( arguments.length <= 1 );
  _.assert( _.numberIs( src ) );

  if( _.atomicIs( src ) )
  self.currentCourse = self._courses[ src ];
  else
  self.currentCourse = self.course( src );

  if( !self.currentCourse )
  throw _.err( 'Failed pick course',src );

  if( self.verbosity )
  logger.log( 'Picked course',self.currentCourse.name );

  return new wConsequence().give();
}

//

// function courseDownload()
// {
//   var self = this;
//
//   _.assert( arguments.length === 0 );
//
//   self._sync
//   .ifNoErrorThen( function()
//   {
//     return self._courseDownload();
//   })
//
//   return self;
// }
//
// //
//
// function _courseDownload()
// {
//   var self = this;
//   var con = new wConsequence().give();
//
//   _.assert( arguments.length === 0 );
//
//   if( self.verbosity )
//   logger.topicUp( 'Downloading course',self.currentCourse,'..' );
//
//   /* login */
//
//   if( !self.loginIsDone() )
//   con.ifNoErrorThen( function()
//   {
//     return self._login();
//   })
//
//   con.ifNoErrorThen( function()
//   {
//     return self._coursesList();
//   })
//   .ifNoErrorThen( function( courses )
//   {
//     if( course === undefined )
//     course = courses[ 0 ];
//     return self._resourcesList( course );
//   })
//   .ifNoErrorThen( function( resources )
//   {
//     return self.makeDownloadsList( resources );
//   })
//   .ifNoErrorThen( function( )
//   {
//     console.log( _.toStr( self.downloadsList, { levels : 2 } ) );
//     return con.give();
//   })
//   .thenDo( function( err,got )
//   {
//     if( self.verbosity )
//     logger.topicDown( 'Downloading of', self.currentCourse, ( err ? 'failed' : 'done' ) + '.' );
//
//     if( err )
//     throw _.errLogOnce( err );
//   });
//
//   return self;
// }

// --
// resources
// --

function resourcesList( course )
{
  var self = this;

  self._sync
  .thenDo( function()
  {
    return self._resourcesList( course );
  })

  return self;
}

//

function _resourcesList()
{
  var self = this;

  if( self.verbosity )
  logger.topicUp( 'List resources for course',self.currentCourse.name,'..' );

  _.assert( arguments.length === 0 );
  _.assert( _.objectIs( self.currentCourse ) );

  return self._resourcesListAct()
  .thenDo( function( err,got )
  {
    if( Config.debug )
    {
      _.each( got, function( resource,k,iteration )
      {
        _.assertMapHasOnly( resource,self.Structure.Resource );
      });
    }

    if( self.verbosity )
    {
      logger.log( 'Resources :' );
      logger.log( _.toStr( self._resources, { levels : 2 } ) );
      logger.log( 'Resources.' );

      if( self.verbosity )
      logger.topicDown( 'Listing of resources .. ' + ( err ? 'failed' : 'done' ) + '.' );
    }

    if( err )
    throw _.errLogOnce( err );

    self.resourceListDone.give();

    return got;
  });

}

//

function resourcesListIsDone()
{
  var self = this;
  return self.resourcesListDone.messageHas();
}

// --
// etc
// --

function updateHeaders( name, value )
{
  /* !!! what is it for? */
  var self = this;
  _.assert( _.strIs( name ) );
  _.assert( _.strIs( value ) );
  self.config.options.headers[ name ] = value;
}

//

function _request( o )
{
  var self = this;
  var con = new wConsequence();

  _.assert( arguments.length === 1 );

  if( _.strIs( o ) )
  o = { url : o };

  logger.log( 'request' );
  logger.log( _.toStr( o,{ levels : 5 } ) );

  var callback = o.callback;
  if( callback )
  _.assert( callback.length === 2,'_request : callback should have 2 arguments : ( err ) and ( got )' );

  o.callback = function requestCallback( err, response, body )
  {

    var got = { response : response , body : body };

    if( callback )
    throw _.err( 'not tested' );

    if( callback )
    con.first( _.routineJoin( undefined,callback,got ) );
    else
    con.give( got );

  }

  self._requestAct( o );

  // logger.log( _.diagnosticStack() );

  return con;
}

// --
// class
// --

function Loader( platform )
{
  var self = this;

  if( platform === undefined )
  {
    return self.Classes[ 'Coursera' ]();
  }
  else
  {
    _.assert( _.strIs( platform ) );

    var className = 'DownloaderOfCourses' + platform;

    _.assert( self.Classes[ className ] );

    return self.Classes[ className ]({ currentPlatform : platform });
  }

}

//

function registerClass()
{
  _.assert( arguments.length > 0 );

  for( var a = 0 ; a < arguments.length ; a++ )
  {
    var child = arguments[ a ];
    this.Classes[ child.nameShort ] = child;
  }

  return this;
}

// --
// structures
// --

var Course = _.like()
.also
({
  name : null,
  id : null,
  url : null,
  username : null,
  raw : null,
})
.end;

//

var Resource = _.like()
.also
({
  name : null,
  id : null,
  url : null,
  type : null,
  childs : null,
  raw : null,
})
.end;

var Structure =
{
  Course : Course,
  Resource : Resource,
}

// --
// relationships
// --

var Composes =
{
  verbosity : 1,
}

var Aggregates =
{
  config : null,

  // siteName : null,

  currentPlatform : null,
  currentCourse : null,
  currentResource : null,

  clearDone : new wConsequence().give(),
  makeDone : new wConsequence(),
  loginDone : new wConsequence(),

  _coursesData : null,
  _courses : null,
  coursesListDone : new wConsequence(),

  _resourcesData : null,
  _resources : null,
  resourceListDone : new wConsequence(),

  _downloadsListTemp : [],
}

var Associates =
{
  _requestAct : null,
  _provider : null,
}

var Restricts =
{
  _sync : null,
}

var Statics =
{
  Request : require( 'request' ),
  Classes : {},
  registerClass : registerClass,
  Loader : Loader,
  Structure : Structure,
}

// --
// proto
// --

var Proto =
{

  init : init,


  // front

  download : download,
  _download : _download,
  clearIsDone : clearIsDone,


  // make

  make : make,
  _make : _make,
  _makeAct : null,
  _makePrepareHeadersForLogin : _makePrepareHeadersForLogin,
  makeIsDone : makeIsDone,


  // login

  _login : _login,
  login : login,
  loginIsDone : loginIsDone,


  // courses

  coursesList : coursesList,
  _coursesList : _coursesList,
  _coursesListAct : _coursesListAct,
  coursesListIsDone : coursesListIsDone,

  course : course,
  coursePick : coursePick,
  _coursePick : _coursePick,

  // courseDownload : courseDownload,
  // _courseDownload : _courseDownload,


  // resources

  resourcesList : resourcesList,
  _resourcesList : _resourcesList,
  _resourcesListAct : null,
  resourcesListIsDone : resourcesListIsDone,


  // etc

  updateHeaders : updateHeaders,
  _request : _request,
  // makeDownloadsList : null,



  // relationships

  constructor : Self,
  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,

};

// define

_.protoMake
({
  constructor : Self,
  parent : Parent,
  extend : Proto,
});

wCopyable.mixin( Self );

// accessor

_.accessor( Self.prototype,
{
});

// readonly

_.accessorReadOnly( Self.prototype,
{
});

wTools[ Self.nameShort ] = _global_[ Self.name ] = Self;

if( typeof module !== 'undefined' )
{
  require( './Coursera.s' );
  require( './Edx.s' );
}

// Self.prototype.Loader();

})();