
a = angular.module 'builder.controller', ['builder.provider']

copyObjectToScope = (object, scope) ->
    ###
    Copy object (ng-repeat="object in objects") to scope without `hashKey`.
    ###
    for key, value of object when key isnt '$$hashKey'
        # copy object.{} to scope.{}
        scope[key] = value
    return


# ----------------------------------------
# fbFormObjectEditableController
# ----------------------------------------
fbFormObjectEditableController = ($scope, $injector) ->
    $builder = $injector.get '$builder'

    $scope.setupScope = (formObject) ->
        ###
        1. Copy origin formObject (ng-repeat="object in formObjects") to scope.
        2. Setup optionsText with formObject.options.
        3. Watch scope.label, .description, .placeholder, .required, .options then copy to origin formObject.
        4. Watch scope.optionsText then convert to scope.options.
        5. setup validationOptions
        ###
        copyObjectToScope formObject, $scope

        $scope.optionsText = formObject.Options.join '\n'

        $scope.$watch '[Label, Description, Placeholder, Required, Options, Validation]', ->
            formObject.Label = $scope.Label
            formObject.Description = $scope.Description
            formObject.Placeholder = $scope.Placeholder
            formObject.Required = $scope.Required
            formObject.Options = $scope.Options
            formObject.Validation = $scope.Validation
        , yes

        $scope.$watch 'optionsText', (text) ->
            $scope.Options = (x for x in text.split('\n') when x.length > 0)
            $scope.inputText = $scope.Options[0]

        component = $builder.components[formObject.Component]
        $scope.validationOptions = component.validationOptions

    $scope.data =
        model: null
        backup: ->
            ###
            Backup input value.
            ###
            @model =
                label: $scope.Label
                description: $scope.Description
                placeholder: $scope.Placeholder
                required: $scope.Required
                optionsText: $scope.optionsText
                validation: $scope.Validation
        rollback: ->
            ###
            Rollback input value.
            ###
            return if not @model
            $scope.Label = @model.label
            $scope.Description = @model.description
            $scope.Placeholder = @model.placeholder
            $scope.Required = @model.required
            $scope.optionsText = @model.optionsText
            $scope.Validation = @model.validation

fbFormObjectEditableController.$inject = ['$scope', '$injector']
a.controller 'fbFormObjectEditableController', fbFormObjectEditableController


# ----------------------------------------
# fbComponentsController
# ----------------------------------------
fbComponentsController = ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'

    # action
    $scope.selectGroup = ($event, group) ->
        $event?.preventDefault()
        $scope.activeGroup = group
        $scope.components = []
        for name, component of $builder.components when component.group is group
            $scope.components.push component

    $scope.groups = $builder.groups
    $scope.activeGroup = $scope.groups[0]
    $scope.allComponents = $builder.components
    $scope.$watch 'allComponents', -> $scope.selectGroup null, $scope.activeGroup

fbComponentsController.$inject = ['$scope', '$injector']
a.controller 'fbComponentsController', fbComponentsController


# ----------------------------------------
# fbComponentController
# ----------------------------------------
fbComponentController = ($scope) ->
    $scope.copyObjectToScope = (object) ->
        copyObjectToScope object, $scope
        $scope.Label = $scope.label
        $scope.Description = $scope.description
        $scope.Placeholder = $scope.placeholder
        $scope.Options = $scope.options
        $scope.Required = $scope.required

fbComponentController.$inject = ['$scope']
a.controller 'fbComponentController', fbComponentController


# ----------------------------------------
# fbFormController
# ----------------------------------------
fbFormController = ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'
    $timeout = $injector.get '$timeout'

    # set default for input
    $scope.input ?= []
    $scope.$watch 'form', ->
        # remove superfluous input
        if $scope.input.length > $scope.form.length
            $scope.input.splice $scope.form.length
        # tell children to update input value
        $timeout -> $scope.$broadcast $builder.broadcastChannel.updateInput
    , yes

fbFormController.$inject = ['$scope', '$injector']
a.controller 'fbFormController', fbFormController


# ----------------------------------------
# fbFormObjectController
# ----------------------------------------
fbFormObjectController = ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'

    $scope.copyObjectToScope = (object) -> copyObjectToScope object, $scope

    $scope.updateInput = (value) ->
        ###
        Copy current scope.input[X] to $parent.input.
        @param value: The input value.
        ###
        input =
            IdNumber: $scope.formObject.IdNumber
            Label: $scope.formObject.Label
            Value: value ? []
        $scope.$parent.input.splice $scope.$index, 1, input

fbFormObjectController.$inject = ['$scope', '$injector']
a.controller 'fbFormObjectController', fbFormObjectController
