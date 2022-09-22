defmodule CraqValidator do
  def execute(questions, nil), do: execute(questions, %{})

  def execute(questions, answers) do
    errors =
      questions
      |> Enum.with_index()
      |> Enum.reduce_while([], fn {_question = %{options: options}, question_index}, errors ->
        case process_answer(options, answers, question_index) do
          {:ok, :continue} -> {:cont, errors}
          {:ok, :complete} -> {:halt, errors}
          {:error, :continue, error} -> {:cont, errors ++ [error]}
          {:error, :complete, error} -> {:halt, errors ++ [error]}
        end
      end)

    if length(errors) == 0 do
      :ok
    else
      errors
      |> Enum.map(fn {question_index, error} -> {String.to_atom("q#{question_index}"), error} end)
      |> Enum.into(%{})
    end
  end

  defp process_answer(options, answers, question_index) do
    question_answer = Enum.at(answers, question_index)

    if is_nil(question_answer) do
      {:error, :continue, {question_index, "was not answered"}}
    else
      {_, selected_option_index} = question_answer
      selected_option = Enum.at(options, selected_option_index)

      process_selected_option(selected_option, answers, question_index)
    end
  end

  defp process_selected_option(_selected_option = nil, _answers, question_index) do
    {:error, :continue,
     {question_index, "has an answer that is not on the list of valid answers"}}
  end

  defp process_selected_option(
         _selected_option = %{complete_if_selected: true},
         answers,
         question_index
       ) do
    next_answer_present = fn answers, question_index ->
      answers |> Enum.at(question_index + 1) |> is_nil |> Kernel.not()
    end

    if next_answer_present.(answers, question_index) do
      {:error, :complete,
       {question_index + 1,
        "was answered even though a previous response indicated that the questions were complete"}}
    else
      {:ok, :complete}
    end
  end

  defp process_selected_option(_selected_option = %{text: _text}, _answers, _question_index),
    do: {:ok, :continue}
end

defmodule QVTest do
  def run_all do
    test1()
    test2()
    test3()
    test4()
    test5()
    test6()
    test7()
    test8()
    test9()
    test10()
    test11()
    test12()
  end

  def test1 do
    description = "it is invalid with no answers"
    questions = [%{text: "q1", options: [%{text: "an option"}, %{text: "another option"}]}]
    answers = %{}

    assert(description, CraqValidator.execute(questions, answers), %{q0: "was not answered"})
  end

  def test2 do
    description = "it is invalid with nil answers"
    questions = [%{text: "q1", options: [%{text: "an option"}, %{text: "another option"}]}]
    answers = nil
    assert(description, CraqValidator.execute(questions, answers), %{q0: "was not answered"})
  end

  def test3 do
    description = "errors are added for all questions"

    questions = [
      %{text: "q1", options: [%{text: "an option"}, %{text: "another option"}]},
      %{text: "q2", options: [%{text: "an option"}, %{text: "another option"}]}
    ]

    answers = nil

    assert(description, CraqValidator.execute(questions, answers), %{
      q0: "was not answered",
      q1: "was not answered"
    })
  end

  def test4 do
    description = "it is valid when an answer is given"
    questions = [%{text: "q1", options: [%{text: "yes"}, %{text: "no"}]}]
    answers = %{q0: 0}
    assert(description, CraqValidator.execute(questions, answers), :ok)
  end

  def test5 do
    description = "it is valid when there are multiple options and the last option is chosen"
    questions = [%{text: "q1", options: [%{text: "yes"}, %{text: "no"}, %{text: "maybe"}]}]
    answers = %{q0: 2}
    assert(description, CraqValidator.execute(questions, answers), :ok)
  end

  def test6 do
    description = "it is invalid when an answer is not one of the valid answers"
    questions = [%{text: "q1", options: [%{text: "an option"}, %{text: "another option"}]}]
    answers = %{q0: 2}

    assert(description, CraqValidator.execute(questions, answers), %{
      q0: "has an answer that is not on the list of valid answers"
    })
  end

  def test7 do
    description = "it is invalid when not all the questions are answered"

    questions = [
      %{text: "q1", options: [%{text: "an option"}, %{text: "another option"}]},
      %{text: "q2", options: [%{text: "an option"}, %{text: "another option"}]}
    ]

    answers = %{q0: 0}
    assert(description, CraqValidator.execute(questions, answers), %{q1: "was not answered"})
  end

  def test8 do
    description = "it is valid when all the questions are answered"

    questions = [
      %{text: "q1", options: [%{text: "an option"}, %{text: "another option"}]},
      %{text: "q2", options: [%{text: "an option"}, %{text: "another option"}]}
    ]

    answers = %{q0: 0, q1: 0}
    assert(description, CraqValidator.execute(questions, answers), :ok)
  end

  def test9 do
    description = "it is valid when questions after complete_if_selected are not answered"

    questions = [
      %{text: "q1", options: [%{text: "yes"}, %{text: "no", complete_if_selected: true}]},
      %{text: "q2", options: [%{text: "an option"}, %{text: "another option"}]}
    ]

    answers = %{q0: 1}
    assert(description, CraqValidator.execute(questions, answers), :ok)
  end

  def test10 do
    description = "it is invalid if questions after complete_if are answered"

    questions = [
      %{text: "q1", options: [%{text: "yes"}, %{text: "no", complete_if_selected: true}]},
      %{text: "q2", options: [%{text: "an option"}, %{text: "another option"}]}
    ]

    answers = %{q0: 1, q1: 0}

    assert(description, CraqValidator.execute(questions, answers), %{
      q1:
        "was answered even though a previous response indicated that the questions were complete"
    })
  end

  def test11 do
    description =
      "it is valid if complete_if is not a terminal answer and further questions are answered"

    questions = [
      %{text: "q1", options: [%{text: "yes"}, %{text: "no", complete_if_selected: true}]},
      %{text: "q2", options: [%{text: "an option"}, %{text: "another option"}]}
    ]

    answers = %{q0: 0, q1: 1}
    assert(description, CraqValidator.execute(questions, answers), :ok)
  end

  def test12 do
    description =
      "it is invalid if complete_if is not a terminal answer and further questions are not answered"

    questions = [
      %{text: "q1", options: [%{text: "yes"}, %{text: "no", complete_if_selected: true}]},
      %{text: "q2", options: [%{text: "an option"}, %{text: "another option"}]}
    ]

    answers = %{q0: 0}
    assert(description, CraqValidator.execute(questions, answers), %{q1: "was not answered"})
  end

  def assert(description, result, expectation) do
    if result == expectation do
      IO.puts("#{description} #{IO.ANSI.green()}SUCCESS#{IO.ANSI.reset()}")
    else
      IO.puts("#{description} #{IO.ANSI.red()}FAIL#{IO.ANSI.reset()}")
      IO.puts("expected ")
      IO.inspect(expectation)
      IO.puts("received ")
      IO.inspect(result)
    end

    IO.puts("")
  end
end

QVTest.run_all()
