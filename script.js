function gradioApp() {
    const elems = document.getElementsByTagName('gradio-app');
    const elem = elems.length == 0 ? document : elems[0];

    if (elem !== document) {
        elem.getElementById = function(id) {
            return document.getElementById(id);
        };
    }
    return elem.shadowRoot ? elem.shadowRoot : elem;
}

function selected_repo(_disabled_list, path) {
    var selected = [];

    gradioApp().querySelectorAll('#select_table input[type="checkbox"]').forEach(function(x) {
        if (x.name.startsWith("select_") && x.checked) {
            selected.push(x.name.substring(7));
        }
    });

    return [JSON.stringify(selected), path];
}