module Api
  module V1
    class TodosController < ApplicationController
      before_action :set_todo, only: [:show, :update, :destroy]

      # GET /api/v1/todos
      def index
        @todos = Todo.all
        render json: @todos
      end

      # GET /api/v1/todos/1
      def show
        cached_todo = REDIS_CLIENT.get("todo:#{params[:id]}")
        
        if cached_todo
          render json: cached_todo
        else
          render json: @todo
        end
      end

      # POST /api/v1/todos
      def create
        @todo = Todo.new(todo_params)

        if @todo.save
          render json: @todo, status: :created
        else
          render json: @todo.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/todos/1
      def update
        if @todo.update(todo_params)
          render json: @todo
        else
          render json: @todo.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/todos/1
      def destroy
        @todo.destroy
        head :no_content
      end

      private

      def set_todo
        @todo = Todo.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Todo not found' }, status: :not_found
      end

      def todo_params
        params.require(:todo).permit(:title, :description, :completed)
      end
    end
  end
end
