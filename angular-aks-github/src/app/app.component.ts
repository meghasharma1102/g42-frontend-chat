import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  template: `
    <main class="page">
      <section class="card">
        <p class="eyebrow">Angular + GitHub Actions + AKS + Helm</p>
        <h1>Angular application deployed to AKS</h1>
        <p class="lead">
          This sample app is ready for Docker build, ACR push, Helm deployment,
          and GitHub Actions automation.
        </p>

        <div class="grid">
          <div class="tile">
            <h2>CI checks</h2>
            <p>Gitleaks, Trivy, SonarQube, and Angular build validation.</p>
          </div>
          <div class="tile">
            <h2>CD target</h2>
            <p>Azure Kubernetes Service in the Delphi environment.</p>
          </div>
          <div class="tile">
            <h2>Authentication</h2>
            <p>Supports both OIDC and Service Principal Secret modes.</p>
          </div>
          <div class="tile">
            <h2>Deployment</h2>
            <p>Helm-based rollout with parameterized GitHub Actions inputs.</p>
          </div>
        </div>

        <div class="footer-note">
          <strong>Next step:</strong> run the GitHub workflow and verify the AKS service external IP.
        </div>
      </section>
    </main>
  `,
  styles: [``]
})
export class AppComponent {}
