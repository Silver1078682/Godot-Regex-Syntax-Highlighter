# Godot Regex Syntax Highlighter
Provides you with a highlighter that *semantically* colorizes regular expressions in your game made with [Godot](https://godotengine.org/).  <br>
It follows the [PCRE2](https://www.pcre.org/) standard, exactly the one Godot used.  <br>

As depicted in the picture below.
![example picture](example/example.png)

## Install
If you just want the highlighter...  <br>
you can simply copy and paste the script file named `regex_syntax_highlighter.gd` from the repo.

If you want the script along with the demo project...  <br>
```sh
git clone https://github.com/Silver1078682/Godot-Regex-Syntax-Highlighter.git
```

## How To Use
After installation, you should be able to highlight a `TextEdit`.  <br>
To do so, simply assign its `syntax_highlighter` property with a new `RegexSyntaxHighlighter` instance.  <br>
The color palette is customizable, you can modify it via inspector.  <br>


## Contributions
If you notice any bug, please feel free to open an issue or PR.  <br>
**NOTE**: Currently the highlighter can only highlight a one-line regex properly, so make sure you are not reporting a bug of a multiline regex.

A bug may include:
* a valid regex marked as error
* an invalid regex not marked as error
* crashes when entering specific regex
* highlighting does not sticks to PCRE2 standard

In following occasion you might not open an issue
* it is covered in [known_issues](known_issues.txt)
* a duplicate issue
