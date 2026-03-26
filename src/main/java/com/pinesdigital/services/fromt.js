let currentPage = 0;
let hasNext = true;

function loadMore() {

    if (!hasNext) return;

    fetch(`/api/dashboard/domains?page=${currentPage}`)
        .then(res => res.json())
        .then(data => {

            const container = document.getElementById("domains-container");

            data.content.forEach(domain => {
                const div = document.createElement("div");
                div.innerText = domain.name + " - " + domain.status;
                container.appendChild(div);
            });

            hasNext = data.hasNext;
            currentPage++;

            if (!hasNext) {
                document.getElementById("load-more-btn").style.display = "none";
            }
        });
}
