'use strict'

require 'moment'
require 'angular-ui-router'
require 'angular-ui-sortable'
require 'angular-gravatar'
require 'angular-elastic'
require 'angular-local-storage'
require 'angular-moment'
require 'ng-showdown'

require './routes.coffee'
require './modules/focusMe/index.coffee'
require './modules/selectize'
require './modules/tagData/index.coffee'
require './modules/userData/index.coffee'
require './modules/auth/index.coffee'
require './modules/bytes/index.coffee'
require './modules/sidebar/index.coffee'
require './modules/navbar/index.coffee'
require './modules/ngBindHtmlUnsafe'
require './modules/strings'
require './modules/mediaComment'
require './modules/redactor'
require './modules/time'
require './modules/www'

angular
    .module 'simple.team', [
        'ngFileUpload'
        'ui.router'
        'ui.sortable'
        'ui.gravatar'
        'ui.bootstrap'
        'selectize'
        'angularMoment'
        'angular-loading-bar'
        'ng-showdown'
        'LocalStorageModule'
        'monospaced.elastic'
        'textAngular'

        'simple.team.routes'
        'simple.team.focusMe'
        'simple.team.ngBindHtmlUnsafe'
        'simple.team.bytes'
        'simple.team.sidebar'
        'simple.team.navbar'
        'simple.team.auth'
        'simple.team.tagData'
        'simple.team.userData'
        'simple.team.www'
    ]

    .config ['$urlRouterProvider', 'cfpLoadingBarProvider', ($urlRouterProvider, cfpLoadingBarProvider) ->
        $urlRouterProvider.otherwise '/projects'
        cfpLoadingBarProvider.includeSpinner = false
        return
    ]

    .controller 'AppCtrl', ['$state', '$http', '$rootScope', ($state, $http, $rootScope) ->
        $rootScope.teams = angular.copy ENV.teams
        $rootScope.authUser = angular.copy ENV.authUser
        $rootScope.s3BucketAttachmentsUrl = angular.copy ENV.s3BucketAttachmentsUrl
        @state = $state

        @s3BucketAttachmentsUrl = $rootScope.s3BucketAttachmentsUrl
        @teams = $rootScope.teams
        $rootScope.$broadcast 'teams:loaded', @teams
        @authUser = $rootScope.authUser
        $rootScope.$broadcast 'user:loaded', @authUser
        $rootScope.$on 'teams:reload', @loadTeams

        init = =>
            @loadTeams()

        @loadTeams = ->
            $http
                .get '/api/teams'
                .success (data) =>
                    @teams = data.teams
                    $rootScope.teams = data.teams

        @setCurrentTeam = (team) ->
            previousTeam = angular.copy @authUser.team
            @authUser.team = team
            $http
                .put '/api/me/team',
                    team_id: team.id
                .success (data) =>
                    if ! data.success then return @authUser.team = previousTeam

                    $state.go($state.current, {}, {reload: true})
                    $rootScope.$broadcast 'team:changed'

        init()

        return
    ]
