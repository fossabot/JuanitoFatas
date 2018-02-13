require "rails_helper"

RSpec.describe RenderMarkdown do
  def render_markdown(content)
    RenderMarkdown.new(content).call
  end

  it "renders text" do
    content = <<~TEXT
      It's very easy to make some words **bold** and other words *italic* with Markdown. You can even [link to Google!](http://google.com)
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p>It's very easy to make some words <strong>bold</strong> and other words <em>italic</em> with Markdown. You can even <a href="http://google.com">link to Google!</a></p>
    TEXT
  end

  it "render lists" do
    content = <<~TEXT
      Sometimes you want numbered lists:
      1. One
      2. Two
      3. Three
      Sometimes you want bullet points:
      * Start a line with a star
      * Profit!
      Alternatively,
      - Dashes work just as well
      - And if you have sub points, put two spaces before the dash or star:
        - Like this
        - And this
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p>Sometimes you want numbered lists:<br>
      1. One<br>
      2. Two<br>
      3. Three<br>
      Sometimes you want bullet points:</p>

      <ul>
      <li>Start a line with a star</li>
      <li>Profit!
      Alternatively,</li>
      <li>Dashes work just as well</li>
      <li>And if you have sub points, put two spaces before the dash or star:

      <ul>
      <li>Like this</li>
      <li>And this</li>
      </ul>
      </li>
      </ul>
    TEXT
  end

  it "renders images" do
    content = <<~TEXT
      If you want to embed images, this is how you do it:
      ![Image of Yaktocat](https://octodex.github.com/images/yaktocat.png)
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p>If you want to embed images, this is how you do it:<br>
      <img src="https://octodex.github.com/images/yaktocat.png" alt="Image of Yaktocat"></p>
    TEXT
  end

  it "renders headers & quotes" do
    content = <<~TEXT
      # Structured documents
      Sometimes it's useful to have different levels of headings to structure your documents. Start lines with a `#` to create headings. Multiple `##` in a row denote smaller heading sizes.
      ### This is a third-tier heading
      You can use one `#` all the way up to `######` six for different heading sizes.
      If you'd like to quote someone, use the > character before the line:
      > Coffee. The finest organic suspension ever devised... I beat the Borg with it.
      > - Captain Janeway
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <h1>Structured documents</h1>

      <p>Sometimes it's useful to have different levels of headings to structure your documents. Start lines with a <code>#</code> to create headings. Multiple <code>##</code> in a row denote smaller heading sizes.</p>

      <h3>This is a third-tier heading</h3>

      <p>You can use one <code>#</code> all the way up to <code>######</code> six for different heading sizes.<br>
      If you'd like to quote someone, use the &gt; character before the line:</p>

      <blockquote>
      <p>Coffee. The finest organic suspension ever devised... I beat the Borg with it.</p>

      <ul>
      <li>Captain Janeway</li>
      </ul>
      </blockquote>
    TEXT
  end

  it "renders code" do
    content = <<~TEXT
      There are many different ways to style code with GitHub's markdown. If you have inline code blocks, wrap them in backticks: `var example = true`.  If you've got a longer block of code, you can indent with four spaces:
          if (isAwesome){
            return true
          }
      GitHub also supports something called code fencing, which allows for multiple lines without indentation:
      ```
      if (isAwesome){
        return true
      }
      ```
      And if you'd like to use syntax highlighting, include the language:
      ```javascript
      if (isAwesome){
        return true
      }
      ```
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p>There are many different ways to style code with GitHub's markdown. If you have inline code blocks, wrap them in backticks: <code>var example = true</code>.  If you've got a longer block of code, you can indent with four spaces:<br>
          if (isAwesome){<br>
            return true<br>
          }<br>
      GitHub also supports something called code fencing, which allows for multiple lines without indentation:</p>

      <pre><code>if (isAwesome){
        return true
      }
      </code></pre>

      <p>And if you'd like to use syntax highlighting, include the language:</p>

      <div class="highlight highlight-javascript"><pre class="highlight"><code><span class="k">if</span> <span class="p">(</span><span class="nx">isAwesome</span><span class="p">){</span>
        <span class="k">return</span> <span class="kc">true</span>
      <span class="p">}</span>
      </code></pre></div>
    TEXT
  end

  it "renders headers" do
    content = <<~TEXT
      # This is an <h1> tag
      ## This is an <h2> tag
      ###### This is an <h6> tag
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <h1>This is an &lt;h1&gt; tag</h1>

      <h2>This is an &lt;h2&gt; tag</h2>

      <h6>This is an &lt;h6&gt; tag</h6>
    TEXT
  end

  it "renders emphasis" do
    content = <<~TEXT
      *This text will be italic*
      _This will also be italic_
      **This text will be bold**
      __This will also be bold__
      _You **can** combine them_
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p><em>This text will be italic</em><br>
      <em>This will also be italic</em><br>
      <strong>This text will be bold</strong><br>
      <strong>This will also be bold</strong><br>
      <em>You <strong>can</strong> combine them</em></p>
    TEXT
  end

  it "renders unordered lists" do
    content = <<~TEXT
      * Item 1
      * Item 2
        * Item 2a
        * Item 2b
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <ul>
      <li>Item 1</li>
      <li>Item 2

      <ul>
      <li>Item 2a</li>
      <li>Item 2b</li>
      </ul>
      </li>
      </ul>
    TEXT
  end

  it "renders ordered lists" do
    content = <<~TEXT
      1. Item 1
      2. Item 2
      3. Item 3
         * Item 3a
         * Item 3b
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <ol>
      <li>Item 1</li>
      <li>Item 2</li>
      <li>Item 3

      <ul>
      <li>Item 3a</li>
      <li>Item 3b</li>
      </ul>
      </li>
      </ol>
    TEXT
  end

  it "renders images 2" do
    content = <<~TEXT
      ![GitHub Logo](/images/logo.png)
      Format: ![Alt Text](url)
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p><img src="/images/logo.png" alt="GitHub Logo"><br>
      Format: <img src="url" alt="Alt Text"></p>
    TEXT
  end

  it "renders links" do
    content = <<~TEXT
      http://github.com - automatic!
      [GitHub](http://github.com)
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p><a href="http://github.com">http://github.com</a> - automatic!<br>
      <a href="http://github.com">GitHub</a></p>
    TEXT
  end

  it "renders blockquotes" do
    content = <<~TEXT
      As Kanye West said:
      > We're living the future so
      > the present is our past.
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p>As Kanye West said:</p>

      <blockquote>
      <p>We're living the future so<br>
      the present is our past.</p>
      </blockquote>
    TEXT
  end

  it "renders inline code" do
    content = <<~TEXT
      I think you should use an
      `<addr>` element here instead.
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p>I think you should use an<br>
      <code>&lt;addr&gt;</code> element here instead.</p>
    TEXT
  end

  it "syntax highlight" do
    content = <<~TEXT
      ```javascript
      function fancyAlert(arg) {
        if(arg) {
          $.facebox({div:'#foo'})
        }
      }
      ```
          function fancyAlert(arg) {
            if(arg) {
              $.facebox({div:'#foo'})
            }
          }
      def foo():
          if not bar:
              return True
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <div class="highlight highlight-javascript"><pre class="highlight"><code><span class="kd">function</span> <span class="nx">fancyAlert</span><span class="p">(</span><span class="nx">arg</span><span class="p">)</span> <span class="p">{</span>
        <span class="k">if</span><span class="p">(</span><span class="nx">arg</span><span class="p">)</span> <span class="p">{</span>
          <span class="nx">$</span><span class="p">.</span><span class="nx">facebox</span><span class="p">({</span><span class="na">div</span><span class="p">:</span><span class="s1">'#foo'</span><span class="p">})</span>
        <span class="p">}</span>
      <span class="p">}</span>
      </code></pre></div>

      <pre><code>function fancyAlert(arg) {
        if(arg) {
          $.facebox({div:'#foo'})
        }
      }
      </code></pre>

      <p>def foo():<br>
          if not bar:<br>
              return True</p>
    TEXT
  end

  it "renders tables" do
    content = <<~TEXT
      First Header | Second Header
      ------------ | -------------
      Content from cell 1 | Content from cell 2
      Content in the first column | Content in the second column
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <table>
      <thead>
      <tr>
      <th>First Header</th>
      <th>Second Header</th>
      </tr>
      </thead>
      <tbody>
      <tr>
      <td>Content from cell 1</td>
      <td>Content from cell 2</td>
      </tr>
      <tr>
      <td>Content in the first column</td>
      <td>Content in the second column</td>
      </tr>
      </tbody>
      </table>
    TEXT
  end

  it "renders autolink" do
    content = <<~TEXT
      hey Donald <trump@example.com>
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p>hey Donald &lt;<a href=\"mailto:trump@example.com\">trump@example.com</a>&gt;</p>
    TEXT
  end

  it "renders strikethrough" do
    content = <<~TEXT
      ~~this~~
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p><del>this</del></p>
    TEXT
  end

  it "sanitizes bad input" do
    content = <<~TEXT
      > quoted text
      123<img src="" onerror="alert(1)" />45678
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <blockquote>
      <p>quoted text<br>
      123&lt;img src="" onerror="alert(1)" /&gt;45678</p>
      </blockquote>
    TEXT
  end

  it "unknown syntax highlight will not cause error" do
    content = <<~TEXT
      ```nolang
      $("#divTest1").text("Hello, world!");
      ```
    TEXT

    expect { render_markdown(content) }.not_to raise_error
  end

  it "Twemoji" do
    content = <<~TEXT
      :heart_eyes:
      :flag-sg:
      :man-heart-man:
      :man-woman-boy:
      :man::skin-tone-5:
      not render `:heart_eyes:`
    TEXT

    html = render_markdown(content)

    expect(html).to eq(<<~TEXT.rstrip)
      <p><img draggable="false" title=":heart_eyes:" alt="😍" src="https://twemoji.maxcdn.com/2/svg/1f60d.svg" class="emoji"><br>
      <img draggable="false" title=":flag-sg:" alt="🇸🇬" src="https://twemoji.maxcdn.com/2/svg/1f1f8-1f1ec.svg" class="emoji"><br>
      <img draggable="false" title=":man-heart-man:" alt="👨‍❤️‍👨" src="https://twemoji.maxcdn.com/2/svg/1f468-200d-2764-fe0f-200d-1f468.svg" class="emoji"><br>
      <img draggable="false" title=":man-woman-boy:" alt="👨‍👩‍👦" src="https://twemoji.maxcdn.com/2/svg/1f468-200d-1f469-200d-1f466.svg" class="emoji"><br>
      <img draggable="false" title=":man::skin-tone-5:" alt="👨🏾" src="https://twemoji.maxcdn.com/2/svg/1f468-1f3fe.svg" class="emoji"><br>
      not render <code>:heart_eyes:</code></p>
    TEXT
  end

  it "linkify github links" do
    content = <<~TEXT
      ```
      blah
      https://github.com/jaunitofatas/campfire/issues/925
      end blah
      ```

      this is my link 1
      - [hello](https://github.com/jaunitofatas/campfire/issues/925)
      - https://github.com/jaunitofatas/campfire/issues/925
      - jaunitofatas/campfire#925
      - `https://github.com/jaunitofatas/campfire/issues/925`
    TEXT

    html = render_markdown(content)

    expect(html).to eq <<~TEXT.rstrip
      <pre><code>blah
      https://github.com/jaunitofatas/campfire/issues/925
      end blah
      </code></pre>

      <p>this is my link 1</p>

      <ul>
      <li><a href="https://github.com/jaunitofatas/campfire/issues/925">hello</a></li>
      <li><a href="https://github.com/jaunitofatas/campfire/issues/925">jaunitofatas/campfire#925</a></li>
      <li>jaunitofatas/campfire#925</li>
      <li><code>https://github.com/jaunitofatas/campfire/issues/925</code></li>
      </ul>
    TEXT
  end
end
