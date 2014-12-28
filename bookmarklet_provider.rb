require 'webrick'
require 'webrick/https'
require 'openssl'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'sinatra/reloader'
require 'net/https'
require 'json'
require 'yaml'

set :environment, :production

conf = YAML.load_file('config.yml')
CURRENT_DIR_PATH = Dir.pwd

class BookmarkletProvider < Sinatra::Base
    register Sinatra::CrossOrigin

    before do
        cross_origin
        content_type :js
    end

    get '/bookmarklet' do
        members = YAML.load_file(File.join(CURRENT_DIR_PATH, 'members.yml'))

        <<-EOS
        (function(d) {
          var url = location.href,
            bookmarklet = d.createElement('div');
          bookmarklet.id = 'bookmarklet';
          bookmarklet.innerHTML += '<div class="buttons">' +
            '<div class="cw-wrapper">' +
            '<div class="cw-buttons clearfix">' +
            '<span class="buttons-name">' +
            '<img src="https://www.chatwork.com/image/favicon/favicon00.ico">Chatwork:' +
            '</span>' +
            '<button type="button" onclick="setChatworkMember(\\'dev\\')">エンジニアメンバーをセット</button>' +
            '<button type="button" onclick="setChatworkMember(\\'all\\')">すべてのメンバーをセット</button>' +
            '</div>' +
            '<div class="cw-checkboxes" clearfix>' +
            '<input id="delete_newline" type="checkbox" name="delete_newline" checked><label for="delete_newline">改行削除</label>' +
            '<input id="has_name" type="checkbox" name="has_name" checked><label for="has_name">名前あり</label>' +
            '</div>' +
            '</div>' +


            /* 閉じる */
            '<div onclick="document.body.removeChild(document.body.firstChild);" class="close">閉じる</div>' +

            '<style>' +
            '#bookmarklet {position: fixed; z-index: 10000; top: 10px; right: 10px; width: 340px; height: 105px; border: solid 6px #C5DCEA; border-radius: 5px; box-shadow: black 1px 1px 8px; font-size: 13px; font-family: sans-serif; color: #4f4f4f; text-align: left; padding: 0; margin: 0; background-color: rgb(223, 244, 255); } #bookmarklet .buttons {margin: 10px 0;padding: 10px; height: 68px; } #bookmarklet .buttons button {width: 200px; float: right; } #bookmarklet .cw-buttons, #bookmarklet .stash-buttons {margin: 5px 10px 5px 0px; } #bookmarklet .cw-checkboxes label {margin-right: 10px; } #bookmarklet .buttons-name {font-size: 15px; font-weight: bold; text-align: right; width: 100px; } #bookmarklet .buttons-name img {width:17px; margin: 0px 3px -1px; } #bookmarklet .close {height:20px; width:80px; background-color:#009fff; color:white; text-align:center; font-size:15px; top:-10px; left:240px; line-height:1; padding:4px 0 0 0; position:absolute; cursor:pointer; } #bookmarklet .clearfix:after {content: ""; clear: both; display: block; }' +
            '</style>';

          setChatworkMember = function(group) {
            if (location.hostname.indexOf('chatwork') == -1) {
              alert('チャットワークのページで実行してください');
              return;
            }
            var cw_textarea = d.getElementById('_chatText');
            cw_textarea.value = cw_textarea.value + getChatworkToMmmbers(group);
            cw_textarea.focus();
          };

          getChatworkToMmmbers = function(group) {
            var members = #{members.to_json};
            var to_texts = {};
            for (var i in members) {
              var to_text = '[To:' + members[i].id + ']';
              if (d.getElementById('has_name').checked) {
                to_text += members[i].name;
              }
              to_text += (!d.getElementById('delete_newline').checked) ? '\\n' : ' ';
              to_texts[members[i].id] = to_text;
            }
            var to_members = '';
            switch (group) {
              case 'dev':
                for (var i in members) {
                  if (members[i].position === 'engineer') {
                    to_members += to_texts[members[i].id];
                  }
                }
                break;
              case 'all':
                for (var i in members) {
                  to_members += to_texts[members[i].id];
                }
                break;
            }
            return to_members;
          };
          d.body.insertBefore(bookmarklet, document.body.firstChild);
        })(document);

        EOS
    end

    get '/permission_for_ssl' do
        'You can SSL connection with your browser.'
    end

end

webrick_options = {
    :Port            => conf['port'],
    :ServerType      => WEBrick::Daemon,
    :SSLEnable       => true,
    :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate  => OpenSSL::X509::Certificate.new(  File.open(conf['cert_path']['certificate']).read),
    :SSLPrivateKey   => OpenSSL::PKey::RSA.new(          File.open(conf['cert_path']['private_key']).read),
    :SSLCertName     => [ [ 'CN',WEBrick::Utils::getservername ] ],
}
Rack::Handler::WEBrick.run BookmarkletProvider, webrick_options
