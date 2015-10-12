'use strict'

module.exports = ($http, $state, $rootScope, $modal) ->
    @isEditCardOpen = false
    @isCreateCardOpen = false
    @projects = []
    @tags = []
    @newCardName = ''
    @openTopCreateCards = {}
    @openBottomCreateCards = {}
    @currentUser = null
    @selectedStage = null
    @selectedCommentBody = ''
    @selectedTaskBody = ''
    @authUser = $rootScope.authUser
    @team = $rootScope.authUser.team
    @filters =
        tag: null
        assignedTo: null

    @sortableOptions = {
        stop: (evt, ui) ->
            if ui.item.sortable.droptarget
                stage = ui.item.sortable.droptarget.scope().stage
                updateStageCards stage
        placeholder: "app"
        connectWith: ".sortable"
    }

    $rootScope.$on 'projects:reload', =>
        @loadProjects()

    init = =>
        @loadProjects()
        @loadTags()

    updateStageCards = (stage) ->
        cardIds = _.pluck stage.cards, 'id'
        $http
            .put '/api/cards/stageOrder',
                card_ids: cardIds
                stage_id: stage.id

    updateProjectOrder = (projects) ->
        projectIds = _.pluck projects, 'id'
        $http
            .post '/api/projects/order',
                project_ids: projectIds

    @selectAssignedToFilter = (newFilter) =>
        @filters.assignedTo = newFilter

    @selectTagFilter = (newFilter) =>
        @filters.tag = newFilter

    @appliedFilters = (card) =>
        if @filters.tag isnt null and _.findIndex(card.tags, { id: @filters.tag.id }) is -1
            return false

        if @filters.assignedTo isnt null and _.findIndex(card.users, { id: @filters.assignedTo.id }) is -1
            return false

        true

    @loadTags = =>
        $http
            .get '/api/tags'
            .success (data) =>
                @tags = data.tags

    @openSortableProjects = ->
        $modal
            .open({
                template: require '../layouts/sortableProjects.modal.html'
                controller: require './sortableProjects.modal.ctrl.coffee'
                controllerAs: 'ctrl'
                size: 'md'
                resolve: {
                    projects: =>
                        @projects
                }
            })
            .result
            .then (projects) =>
                @projects = projects
                updateProjectOrder(projects)

    @loadProjects = ->
        $http
            .get '/api/projects'
            .success (data) =>
                @projects = data.projects

    @openSortStagesModal = =>
        @stagesCopy = angular.copy @stages

    @updateStagesOrder = (stagesCopy) =>
        _.each stagesCopy, (stage, key) =>
            realStage = _.find(@stages, { $id: stage.$id })
            realStage.$priority = key
            @stages.$save(realStage)

    @deleteProject = (project) =>
        if ! confirm("Delete '" + project.name + "' and all it's contents?") then return
        _.remove @projects, project
        $http.delete '/api/projects/' + project.id

    @createProject = ->
        projectName = prompt("New Project Name")
        if ! projectName then return

        $http
            .post '/api/projects',
                name: projectName
                stages: [
                    {
                        name: 'New'
                    },
                    {
                        name: 'In Progress'
                    },
                    {
                        name: 'Closed'
                    }
                ]
            .success (data) =>
                @projects = data.projects

    @deleteStage = (project, stageIndex) ->
        if confirm 'Delete this stage?'
            project.stages.splice stageIndex, 1

    @toggleProjectVisibility = (project) ->
        project.hidden = !project.hidden

    @editStage = (stage) ->
        newStageName = prompt('Edit Stage Name', stage.name)
        if (! newStageName) then return
        stage.name = newStageName

    @deleteAllCardsInStage = (stage) ->
        if ! confirm('Delete all cards in this stage?') then return
        stage.cards = []
        $http.delete '/api/stages/' + stage.id + '/cards'

    @createStage = =>
        stageName = prompt("Stage name")
        if (stageName is null) then return

        newStage = {
            id: createId()
            name: stageName
            createdAt: (new Date).getTime()
        }

        result = @stages.$add(newStage)

        _.each @projects, (project) =>
            project.stages = project.stages || []
            project.stages.push(newStage)
            @projects.$save(project)

    @createCard = (stage) =>
        if @newCardName.length is 0 then return
        @newCardName = @newCardName.replace("\n", '')
        $http
            .post '/api/cards',
                stage_id: stage.id
                name: @newCardName
                addOnTop: !!@openTopCreateCards[stage.id]
            .success (data) ->
                stage.cards.push data.card

        @newCardName = ''

    @openTopCreateCard = (stage, card) =>
        @openTopCreateCards = {}
        @openTopCreateCards[stage.id] = @openTopCreateCards[stage.id] || {}
        @openTopCreateCards[stage.id] = true

    @hideCreateCard = =>
        @openTopCreateCards = {}

    @editProject = (project) ->
        projectName = prompt("Project name", project.name)
        if (projectName is null) then return

        project.name = projectName

        $http
            .put '/api/projects/' + project.id,
                name: project.name
            .success (data) =>
                projectIndex = _.indexOf(@projects, _.find(@projects, { id: project.id }))
                if cardIndex > -1
                    @projects.splice(projectIndex, 1, project)

    @openEditCard = (card) ->
        $state.go 'projects.card',
            cardId: card.id

    init()

    return
