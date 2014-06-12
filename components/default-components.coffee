angular.module 'builder.components', ['builder', 'validator.rules']

.config ['$builderProvider', ($builderProvider) ->
    # ----------------------------------------
    # text input
    # ----------------------------------------
    $builderProvider.registerComponent 'textInput',
        group: 'Default'
        label: 'Text Input'
        description: 'description'
        placeholder: 'placeholder'
        required: no
        validationOptions: [
            {label: 'none', rule: '/.*/'}
            {label: 'number', rule: '[number]'}
            {label: 'email', rule: '[email]'}
            {label: 'url', rule: '[url]'}
        ]
        template:
            """
            <div class="form-group">
                <label for="{{formName+OrderBy}}" class="col-md-4 control-label" ng-class="{'fb-required':Required}">{{Label}}</label>
                <div class="col-md-8">
                    <input type="text" ng-model="inputText" validator-required="{{Required}}" validator-group="{{formName}}" id="{{formName+OrderBy}}" class="form-control" placeholder="{{Placeholder}}"/>
                    <p class='help-block'>{{Description}}</p>
                </div>
            </div>
            """
        popoverTemplate:
            """
            <form>
                <div class="form-group">
                    <label class='control-label'>Label</label>
                    <input type='text' ng-model="Label" validator="[required]" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Description</label>
                    <input type='text' ng-model="Description" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Placeholder</label>
                    <input type='text' ng-model="Placeholder" class='form-control'/>
                </div>
                <div class="checkbox">
                    <label>
                        <input type='checkbox' ng-model="Required" />
                        Required</label>
                </div>
                <div class="form-group" ng-if="validationOptions.length > 0">
                    <label class='control-label'>Validation</label>
                    <select ng-model="$parent.Validation" class='form-control' ng-options="option.rule as option.label for option in validationOptions"></select>
                </div>

                <hr/>
                <div class='form-group'>
                    <input type='submit' ng-click="popover.save($event)" class='btn btn-primary' value='Save'/>
                    <input type='button' ng-click="popover.cancel($event)" class='btn btn-default' value='Cancel'/>
                    <input type='button' ng-click="popover.remove($event)" class='btn btn-danger' value='Delete'/>
                </div>
            </form>
            """

    # ----------------------------------------
    # Text area
    # ----------------------------------------
    $builderProvider.registerComponent 'textArea',
        group: 'Default'
        label: 'Text Area'
        description: 'description'
        placeholder: 'placeholder'
        required: no
        template:
            """
            <div class="form-group">
                <label for="{{formName+OrderBy}}" class="col-md-4 control-label" ng-class="{'fb-required':Required}">{{Label}}</label>
                <div class="col-md-8">
                    <textarea type="text" ng-model="inputText" validator-required="{{Required}}" validator-group="{{formName}}" id="{{formName+OrderBy}}" class="form-control" rows='6' placeholder="{{Placeholder}}"/>
                    <p class='help-block'>{{Description}}</p>
                </div>
            </div>
            """
        popoverTemplate:
            """
            <form>
                <div class="form-group">
                    <label class='control-label'>Label</label>
                    <input type='text' ng-model="Label" validator="[required]" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Description</label>
                    <input type='text' ng-model="Description" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Placeholder</label>
                    <input type='text' ng-model="Placeholder" class='form-control'/>
                </div>
                <div class="checkbox">
                    <label>
                        <input type='checkbox' ng-model="Required" />
                        Required</label>
                </div>

                <hr/>
                <div class='form-group'>
                    <input type='submit' ng-click="popover.save($event)" class='btn btn-primary' value='Save'/>
                    <input type='button' ng-click="popover.cancel($event)" class='btn btn-default' value='Cancel'/>
                    <input type='button' ng-click="popover.remove($event)" class='btn btn-danger' value='Delete'/>
                </div>
            </form>
            """

    # ----------------------------------------
    # checkbox
    # ----------------------------------------
    $builderProvider.registerComponent 'checkbox',
        group: 'Default'
        label: 'Checkbox'
        description: 'description'
        placeholder: 'placeholder'
        required: no
        options: ['value one', 'value two']
        arrayToText: yes
        template:
            """
            <div class="form-group">
                <label for="{{formName+OrderBy}}" class="col-md-4 control-label" ng-class="{'fb-required':Required}">{{Label}}</label>
                <div class="col-md-8">
                    <input type='hidden' ng-model="inputText" validator-required="{{Required}}" validator-group="{{formName}}"/>
                    <div class='checkbox' ng-repeat="item in Options track by $index">
                        <label><input type='checkbox' ng-model="$parent.inputArray[$index]" value='item'/>
                            {{item}}
                        </label>
                    </div>
                    <p class='help-block'>{{Description}}</p>
                </div>
            </div>
            """
        popoverTemplate:
            """
            <form>
                <div class="form-group">
                    <label class='control-label'>Label</label>
                    <input type='text' ng-model="Label" validator="[required]" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Description</label>
                    <input type='text' ng-model="Description" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Options</label>
                    <textarea class="form-control" rows="3" ng-model="OptionsText"/>
                </div>
                <div class="checkbox">
                    <label>
                        <input type='checkbox' ng-model="Required" />
                        Required
                    </label>
                </div>

                <hr/>
                <div class='form-group'>
                    <input type='submit' ng-click="popover.save($event)" class='btn btn-primary' value='Save'/>
                    <input type='button' ng-click="popover.cancel($event)" class='btn btn-default' value='Cancel'/>
                    <input type='button' ng-click="popover.remove($event)" class='btn btn-danger' value='Delete'/>
                </div>
            </form>
            """

    # ----------------------------------------
    # radio
    # ----------------------------------------
    $builderProvider.registerComponent 'radio',
        group: 'Default'
        label: 'Radio'
        description: 'description'
        placeholder: 'placeholder'
        required: no
        options: ['value one', 'value two']
        template:
            """
            <div class="form-group">
                <label for="{{formName+OrderBy}}" class="col-md-4 control-label" ng-class="{'fb-required':Required}">{{Label}}</label>
                <div class="col-md-8">
                    <div class='radio' ng-repeat="item in Options track by $index">
                        <label><input name='{{formName+OrderBy}}' ng-model="$parent.inputText" validator-group="{{formName}}" value='{{item}}' type='radio'/>
                            {{item}}
                        </label>
                    </div>
                    <p class='help-block'>{{Description}}</p>
                </div>
            </div>
            """
        popoverTemplate:
            """
            <form>
                <div class="form-group">
                    <label class='control-label'>Label</label>
                    <input type='text' ng-model="Label" validator="[required]" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Description</label>
                    <input type='text' ng-model="Description" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Options</label>
                    <textarea class="form-control" rows="3" ng-model="OptionsText"/>
                </div>

                <hr/>
                <div class='form-group'>
                    <input type='submit' ng-click="popover.save($event)" class='btn btn-primary' value='Save'/>
                    <input type='button' ng-click="popover.cancel($event)" class='btn btn-default' value='Cancel'/>
                    <input type='button' ng-click="popover.remove($event)" class='btn btn-danger' value='Delete'/>
                </div>
            </form>
            """

    # ----------------------------------------
    # select
    # ----------------------------------------
    $builderProvider.registerComponent 'select',
        group: 'Default'
        label: 'Select'
        description: 'description'
        placeholder: 'placeholder'
        required: no
        options: ['value one', 'value two']
        template:
            """
            <div class="form-group">
                <label for="{{formName+OrderBy}}" class="col-md-4 control-label">{{Label}}</label>
                <div class="col-md-8">
                    <select ng-options="value for value in Options" id="{{formName+OrderBy}}" class="form-control"
                        ng-model="inputText" ng-init="inputText = Options[0]"/>
                    <p class='help-block'>{{Description}}</p>
                </div>
            </div>
            """
        popoverTemplate:
            """
            <form>
                <div class="form-group">
                    <label class='control-label'>Label</label>
                    <input type='text' ng-model="Label" validator="[required]" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Description</label>
                    <input type='text' ng-model="Description" class='form-control'/>
                </div>
                <div class="form-group">
                    <label class='control-label'>Options</label>
                    <textarea class="form-control" rows="3" ng-model="OptionsText"/>
                </div>

                <hr/>
                <div class='form-group'>
                    <input type='submit' ng-click="popover.save($event)" class='btn btn-primary' value='Save'/>
                    <input type='button' ng-click="popover.cancel($event)" class='btn btn-default' value='Cancel'/>
                    <input type='button' ng-click="popover.remove($event)" class='btn btn-danger' value='Delete'/>
                </div>
            </form>
            """
]
