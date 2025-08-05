let settingPreset = false;
const channelInput = document.getElementById("radio-channel");

const sendNuiEvent = (name, data, callback) => {
    $.post(`https://ac_radio/${name}`, JSON.stringify(data), callback);
}

const setLocale = (locales) => {
    for (const [key, value] of Object.entries(locales)) {
        $(`#${key.slice(3)}`).attr('tooltip', value);
    }
}

const closeUi = () => {
    $('.wrapper').fadeOut();
    settingPreset = false;
}



// event listeners
window.addEventListener('message', (event) => {
    const { action, data } = event.data;

    if (action == 'openUi') {
        $('.wrapper').fadeIn();
    } else if (action == 'setLocale') {
        setLocale(data);
    } else if (action == 'closeUi') {
        closeUi();
    } else if (action == 'volume') {
        document.getElementById("volume").innerHTML = data + "%"
    } else if (action == 'mute') {
        document.getElementById("is-not-muted").style.display = "none"
        document.getElementById("is-muted").style.display = "block"
    } else if (action == 'unmute') {
        document.getElementById("is-muted").style.display = "none"
        document.getElementById("is-not-muted").style.display = "block"
    }
});

window.addEventListener('load', () => {
    sendNuiEvent('getConfig', null, (config) => {
        $('#radio-channel').attr({
            max: config.max,
            placeholder: config.max,
            min: config.step,
            step: config.step
        });

        setLocale(config.locales);
    });
});

window.addEventListener('keyup', (key) => {
    if (key.code == 'Escape' && $('.wrapper').is(':visible')) {
        sendNuiEvent('closeUi');
        closeUi();
    };
});

channelInput.addEventListener("keyup", function () {
    var channel = channelInput.value;
    if (channel.length) {
        // check if there is more than 3 decimals
        var decimals = channel.split(".")[1];
        if (decimals && decimals.length > 3) {
            var channel = parseFloat(channel).toFixed(3);
            channelInput.value = channel;
        }
    }
})

const enableVolumeAndMute = (show) => {
    document.getElementById("volume").style.opacity = show ? 1 : 0
    document.querySelector(".mute-status").style.opacity = show ? 1 : 0
}

// radio control functions
const toggleRadio = (join) => {
    let frequency = $('#radio-channel').val();
    if (join && frequency.length) {
        sendNuiEvent('joinFrequency', frequency, (frequency) => {
            $('#radio-channel').val(frequency || '');
        });
        enableVolumeAndMute(true)
    } else if (!join) {
        sendNuiEvent('leaveFrequency');
        $('#radio-channel').val('');
        enableVolumeAndMute(false)
    }
}

const presetChannel = (presetId) => {
    if (settingPreset) {
        sendNuiEvent('presetSet', presetId);
        settingPreset = false;
    } else {
        sendNuiEvent('presetJoin', presetId, (frequency) => {
            $('#radio-channel').val(frequency || '');
            enableVolumeAndMute(true)
        });
    }
}

const setPreset = () => {
    let frequency = $('#radio-channel').val();
    if (frequency.length) {
        sendNuiEvent('presetRequest', frequency);
        settingPreset = true;
    }
}

sendNuiEvent('ready');
