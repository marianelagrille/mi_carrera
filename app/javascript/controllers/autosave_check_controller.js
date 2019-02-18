import { Controller } from "stimulus"

export default class extends Controller {
  update() {
    Rails.fire(this.element, 'submit');
  }

  updateCredits(event) {
    let credits = event.detail[0]["credits"];

    document.querySelector(".js-credits-count").innerHTML = credits;
  }
}
