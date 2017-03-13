# Cerulean

## API DSL for Rails

Cerulean is a reasonably unopinionated DSL for writing APIs in Rails. 

## Installation

Add a reference to Cerulean in your `Gemfile`:

```ruby
gem 'cerulean'
```

Include Cerulean in your base controller class:

```ruby
class ApplicationController < ActionController::API
  include Cerulean
end
```

Or include it in individual controllers as-needed:

```ruby
class PostsController < ApplicationController
  include Cerulean
end
```

## Documentation

### Defining Endpoints

Cerulean provides methods for `get`, `post`, `put`, and `delete`.

The basic structure of a request looks like this:

```ruby
get :index do
  request do
    # ...
  end
end
```

### Params

Cerulen provides basic parameter validation for a variety of common data types.

Request parameters are defined in a `params` block:

```ruby
get :show do
  params do
    param :id, Integer, required: true
  end
  request do
    # ...
  end
end
```

While the raw params can still be accessed inside of your request block via the `params` variable, when declaring a `params` block for an endpoint, you should use `declared` instead.

For example, for the above endpoint, you could access the `id` via `declared[:id]`.

The following param types are supported:

* `String`
* `Integer`
* `Float`
* `Boolean`
* `Date`
* `DateTime`

Arrays are also supported using `Array[Foo]` where `Foo` is one of the primitive types listed above.

#### Validations

* `min`
* `max`
* `required`
* `values`
* `default`

When parameter validation fails, a `Cerulean::InvalidParams` exception will be raised. Validation error messages can be accessed via the `errors` property of the exception. For example:

```ruby
{
  username: ['is required'],
  length: ['is not a float'],
  age: ['must be less than or equal to 100']
}
```

### Presenters

Presenters are classes which satisfy two criteria:

* They accept a model instance as an argument to their constructor.
* They implement an `as_json` method.

Cerulean provides the `presenter` method to declare a presenter for an endpoint, and a `present` method to instantiate that presenter, call `as_json`, and automatically return the result.

#### Example

##### Presenter

```ruby
class FooPresenter
  def initialize(foo)
    @foo = foo
  end

  def as_json()
    @foo.as_json
  end
end
```

##### Controller Action

```ruby
get :show do
  params do
    param :id, Integer, required: true
  end
  presenter FooPresenter
  request do
    present Foo.find(declared[:id])
  end
end
```

### Forms

Forms are classes which accept a params hash as an argument to their constructor.

Cerulean provides the `form` method for declaring the form for an endpoint. The form will be instantiated automatically using the `params` hash from the action and can be accessed via `@form`.

#### Example 

##### JSON

```json
{
  "name": "Hello World"
}
```

##### Form Object

```ruby
class FooForm
  def initialize(params)
    @foo = params.has_key?(:id) && Foo.find_by(id: params[:id]) || Foo.new
  end

  attribute :name, String
  
  def errors
    @foo.errors
  end

  def valid?
    build
    @foo.valid?
  end

  def save!
    build
    @foo.save!
    @foo
  end

  private

  def build
    @foo.name = self.name
  end
end
```

##### Controller Action

```ruby
post :create do
  form :foo, FooForm
  presenter FooPresenter
  request do
    present @form.save!
  end
end
```

#### Specifying an Alternate Key

The `form` method takes an optional keyword argument, `key`. This allows you to grab just a piece of your JSON payload for binding to the form object.

##### JSON

```json
{
  "foo": {
    "name": "Hello World"
  }
}
```

##### Controller Action

```ruby
post :create do
  form :foo, FooForm, key: :foo
  # ...
end
```

## License (MIT)

Copyright (c) 2017 Kyle Kestell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.