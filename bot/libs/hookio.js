// https://unnikked.ga/build-telegram-bot-hook-io/

module['exports'] = function relayBot (hook) {
  var request = require('request');
  var msg = hook.params.message;
  var TOKEN = hook.env.merbot_key; // change env to reflect your bot
  var MASTER = hook.env.mimin_teh_bot; // change env to your tg-cli bots id
  var closetag = '}};return _;end';
  var textmessage =  msg.text;

  if (textmessage.match(/^!.*/)) {
    var fmessage = 'do local _={message={chat={title="' + msg.chat.title +
      '",id=' + msg.chat.id +
      ',type="' + msg.chat.type +
      '",username="' + msg.chat.username +
      '",first_name="' + msg.chat.first_name +
      '"},from={first_name="' + msg.from.first_name +
      '",id=' + msg.from.id +
      ',username="' + msg.from.username +
      '"},date=' + msg.date +
      ',text="' + msg.text +
      '",message_id=' + msg.message_id;

  if (msg.new_chat_title) {
    var fmessage = fmessage + ',new_chat_title="' + msg.new_chat_title + '"'
  }

  if (msg.new_chat_participant) {
    var fmessage = fmessage + ',new_chat_participant={first_name="' +
      msg.new_chat_participant.first_name +
      '",id=' + msg.new_chat_participant.id +
      ',username="' + msg.new_chat_participant.username + '"}';
  }

  if (msg.left_chat_participant) {
    var fmessage = fmessage + ',left_chat_participan={first_name="' +
      msg.left_chat_participant.first_name +
      '",id=' + msg.left_chat_participant.id +
      ', username="' + msg.left_chat_participant.username + '"}';
  }

  if (msg.new_chat_photo) {
    var fmessage = fmessage + ',new_chat_photo={}'
  }

  if (msg.delete_chat_photo) {
    var fmessage = fmessage + ',delete_chat_photo = true'
  }

  if (msg.reply_to_message) {
    var reply = msg.reply_to_message
    var fmessage = fmessage +
      ',reply_to_message={chat={id=' + reply.chat.id +
      ',title="' + reply.chat.title +
      '",type="' + reply.chat.type +
      '",username="' + reply.chat.username +
      '"},date=' + reply.date +
      ',from={first_name="' + reply.from.first_name +
      '",id=' + reply.from.id +
      ',type=' + reply.from.type +
      ',username="' + reply.from.username +
      '"},message_id=' + reply.message_id +
      ',text="' + reply.text + '"},';
    }

    request
      .post('https://api.telegram.org/bot' + TOKEN + '/sendMessage')
      .form({
        "chat_id": MASTER,
        "text": fmessage + closetag,
    });
  };
};