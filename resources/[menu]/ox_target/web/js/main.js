import { createOptions } from "./createOptions.js";
import { fetchNui } from "./fetchNui.js";
let clicked = false

const optionsWrapper = document.getElementById("options-wrapper");
const body = document.body;

window.addEventListener("message", (event) => {
    optionsWrapper.innerHTML = "";

    switch (event.data.event) {
        case "visible": {
            body.style.visibility = event.data.state ? "visible" : "hidden";
            clicked = false
        }

        case "setTarget": {
            switchClick(false)
            if (event.data.options) {
                for (const type in event.data.options) {
                    event.data.options[type].forEach((data, id) => {
                        createOptions(type, data, id + 1);
                    });
                }
            }

            if (event.data.zones) {
                for (let i = 0; i < event.data.zones.length; i++) {
                    event.data.zones[i].forEach((data, id) => {
                        createOptions("zones", data, id + 1, i + 1);
                    });
                }
            }
        }
    }
});

export function switchClick(state) {
    clicked = state
}
window.addEventListener("click", () => {
    if (optionsWrapper.innerHTML == "" || clicked) {
        clicked = false
        fetchNui("hasMenuOpen", {
            value: false
        })
        return
    }

    clicked = true
    fetchNui("hasMenuOpen", {
        value: true
    })
})

window.addEventListener("mousemove", (event) => {
    if (clicked) return
    optionsWrapper.style.top = (event.clientY + 10) + "px"
    optionsWrapper.style.left = (event.clientX + 10) + "px"
})
