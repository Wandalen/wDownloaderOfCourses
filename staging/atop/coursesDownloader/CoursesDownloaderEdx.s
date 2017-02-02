( function _CoursesDownloader_s_( ) {

'use strict';

// dependencies

if( typeof module !== 'undefined' )
{
}

// constructor

var _ = wTools;
var Parent = wCoursesDownloader;
var Self = function wCoursesDownloaderEdx( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  return o;
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'CoursesDownloaderEdx';

// --
// inter
// --

function init( o )
{
  var self = this;
  Parent.prototype.init.call( self,o );
}

//

function _makeAct()
{
  var self = this;

  self.config.options.form = self.config.payload;

}

//

function _makePrepareHeadersForLogin()
{
  var self = this;
  var con = Parent.prototype._makePrepareHeadersForLogin.call( self );

  function _getCSRF3( cookies )
  {
    console.log(cookies);
    var src =  cookies[ 0 ];
    src = src.split( ';' )[ 0 ];
    src = src.split( '=' );

    var token = src.pop();

    self.config.options.headers =
    {
      'Referer' : self.config.loginPageUrl,
      'X-CSRFToken' : token
    }

    con.give();
  }

  con.thenDo( _.routineSeal( self,self._request,[ self.config.loginPageUrl ] ) )
  .thenDo( function( err, got )
  {
    if( err )
    err = _.err( err );

    if( got.response.statusCode !== 200 )
    err = _.err( 'Failed to get resources list. StatusCode: ', got.response.statusCode, 'Server response: ', got.body );

    if( err )
    return con.error( err );

    return _getCSRF3( got.response.headers[ 'set-cookie' ] );

  });

  return con;
}

//

function _coursesListAct()
{
  var self = this;

  var con = self._request( self.config.enrollmentUrl )
  .thenDo( function( err, got )
  {

    if( !err )
    if( got.response.statusCode !== 200 )
    err = _.err( 'Failed to get resources list. StatusCode : ', got.response.statusCode, 'Server response : ', got.body );

    if( err )
    return con.error( _.err( err ) );

    // self._provider.fileWrite({ pathFile : './edx_pages/dashboard.html', data : got.body, sync : 1 });
    self._coursesData = JSON.parse( got.body );

    if( !self._courses )
    self._courses = [];

    self._coursesData.forEach( function( course )
    {
      var course_details = course.course_details;
      var name = course_details.course_name;
      var id = course_details.course_id;
      var url = _.strReplaceAll( self.config.courseUrl,'{course_id}', id );

      self._courses.push( { name : name, id : id, url : url, username : course.user } );
    });

    con.give( self._courses );

  });

  return con;

}

//

function _resourcesListAct()
{
  var self = this;
  var con = new wConsequence();

  _.assert( arguments.length === 0 );
  _.assert( _.objectIs( self.currentCourse ) );

  var urlOptions =
  {
    dst : self.config.courseBlocksUrl,
    dictionary :
    {
      '{course_id}' : encodeURIComponent( self.currentCourse.id ),
      '{username}' : self.currentCourse.username
    }
  }

  var getUrl = _.strReplaceAll( urlOptions );

  /* */

  con = self._request( getUrl )
  .thenDo( function( err, got )
  {

    if( !err )
    if( got.response.statusCode !== 200 )
    err = _.err( 'Failed to get resources list. StatusCode : ', got.response.statusCode, 'Server response : ', got.body );

    if( err )
    return con.error( _.err( err ) );

    var data = JSON.parse( got.body );

    self._resourcesData = data;

  })
  .ifNoErrorThen(function () {

    return self._resourcesListParseAct( );
  })
  .ifNoErrorThen(function () {

    con.give( self._resources );
  })


  /* */

  if( self.verbosity )
  {
    con.ifNoErrorThen( function( resources )
    {
      logger.log( 'Resources:\n', _.toStr( resources, { json : 3 } ) );
      con.give( resources );
    });
  }

  return con;
}

//

function _resourcesListParseAct()
{
  var self = this;
  var con = new wConsequence().give();

  function parseBlockChilds( block )
  {
   //parse each child block here
   return block.children;
  }

  if( !self._resources )
  self._resources = [];

  self._resourcesData.forEach( function( block )
  {

    if( block.type === 'chapter' )
    {
      var currentBlock = { name :  block.display_name, id : block.block_id, childs : [],url : block.student_view_url };
      currentBlock.childs.push( parseBlockChilds( block ) )
      self._resources.push( currentBlock );
    }

  });

  return con;
}

// --
// relationships
// --

var Composes =
{
}

var Aggregates =
{
}

var Associates =
{
}

var Restricts =
{
}

var Statics =
{
}

// --
// proto
// --

var Proto =
{

  init : init,

  _makeAct : _makeAct,
  _makePrepareHeadersForLogin : _makePrepareHeadersForLogin,

   //

  _coursesListAct : _coursesListAct,

  //

  _resourcesListAct : _resourcesListAct,
  _resourcesListParseAct : _resourcesListParseAct,


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


// accessor

_.accessor( Self.prototype,
{
});

// readonly

_.accessorReadOnly( Self.prototype,
{
});

_.CoursesDownloader.registerClass( Self );

})();
