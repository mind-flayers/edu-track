import { Sidebar } from "@/components/ui/sidebar";
import { Header } from "@/components/ui/header";
import { PageTransition } from "@/components/ui/page-transition";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-indigo-50/20 to-slate-50">
      <Sidebar />
      <div className="lg:pl-72 transition-all duration-300">
        <Header />
        <main className="p-6 lg:p-8 pt-28">
          <PageTransition>
            {children}
          </PageTransition>
        </main>
      </div>
    </div>
  );
}
