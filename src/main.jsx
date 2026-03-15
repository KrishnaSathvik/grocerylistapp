import React from "react";
import ReactDOM from "react-dom/client";
import { Analytics } from "@vercel/analytics/react";
import GroceryList from "./GroceryList";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <GroceryList />
    <Analytics />
  </React.StrictMode>
);
