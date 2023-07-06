

function selected_repo(_disabled_list, path) {
    var selected = [];
    
    const elems = document.getElementsByTagName('gradio-app');
    const elem = elems.length == 0 ? document : elems[0];

    if (elem !== document) {
        elem.getElementById = function(id) {
            return document.getElementById(id);
        };
    }
    const app_ele = elem.shadowRoot ? elem.shadowRoot : elem;

    app_ele.querySelectorAll('#select_table input[type="checkbox"]').forEach(function(x) {
        if (x.name.startsWith("select_") && x.checked) {
            selected.push(x.name.substring(7));
        }
    });

    return [JSON.stringify(selected), path];
}